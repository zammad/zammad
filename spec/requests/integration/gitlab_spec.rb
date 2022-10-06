# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# rubocop:disable RSpec/StubbedMock,RSpec/MessageSpies

RSpec.describe 'GitLab', type: :request, required_envs: %w[GITLAB_ENDPOINT GITLAB_APITOKEN] do

  let(:token)    { 't0k3N' }
  let(:endpoint) { 'https://git.example.com/api/graphql' }

  let!(:admin) do
    create(:admin, groups: Group.all)
  end

  let!(:agent) do
    create(:agent, groups: Group.all)
  end

  let(:issue_data) do
    {
      id:         '1',
      title:      'Example issue',
      url:        ENV['GITLAB_ISSUE_LINK'],
      icon_state: 'open',
      milestone:  'important milestone',
      assignees:  ['zammad-robot'],
      labels:     [
        {
          color:      '#FF0000',
          text_color: '#FFFFFF',
          title:      'critical'
        },
        {
          color:      '#0033CC',
          text_color: '#FFFFFF',
          title:      'label1'
        },
        {
          color:      '#D1D100',
          text_color: '#FFFFFF',
          title:      'special'
        }
      ],
    }
  end

  let(:dummy_schema) do
    {
      a: :b
    }
  end

  describe 'request handling' do
    it 'does verify integration' do
      params = {
        endpoint:  endpoint,
        api_token: token,
      }
      authenticated_as(agent)
      post '/api/v1/integration/gitlab/verify', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['error']).to eq('Not authorized (user)!')

      authenticated_as(admin)
      instance = instance_double(GitLab)
      expect(GitLab).to receive(:new).with(endpoint, token).and_return instance
      expect(instance).to receive(:verify!).and_return(true)

      post '/api/v1/integration/gitlab/verify', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['result']).to eq('ok')
    end

    it 'does query objects' do
      params = {
        links: [ ENV['GITLAB_ISSUE_LINK'] ],
      }
      authenticated_as(agent)
      instance = instance_double(GitLab)
      expect(GitLab).to receive(:new).and_return instance
      expect(instance).to receive(:issues_by_urls).and_return([issue_data])

      post '/api/v1/integration/gitlab', params: params, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['result']).to eq('ok')
      expect(json_response['response']).to eq([issue_data.deep_stringify_keys])
    end

    it 'does save ticket issues' do
      ticket = create(:ticket, group: Group.first)

      params = {
        ticket_id:   ticket.id,
        issue_links: [ ENV['GITLAB_ISSUE_LINK'] ],
      }
      authenticated_as(agent)
      post '/api/v1/integration/gitlab_ticket_update', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['result']).to eq('ok')

      expect(ticket.reload.preferences[:gitlab][:issue_links]).to eq(params[:issue_links])
    end
  end
end

# rubocop:enable RSpec/StubbedMock,RSpec/MessageSpies
