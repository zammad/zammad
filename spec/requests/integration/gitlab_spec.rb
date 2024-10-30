# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# rubocop:disable RSpec/StubbedMock,RSpec/MessageSpies

RSpec.describe 'GitLab', required_envs: %w[GITLAB_ENDPOINT GITLAB_APITOKEN], type: :request do
  let(:token)      { 't0k3N' }
  let(:endpoint)   { 'https://git.example.com/api/graphql' }
  let(:verify_ssl) { true }
  let(:issue_link) { 'https://git.example.com/project/repo/-/issues/1' }

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
      url:        issue_link,
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

  describe 'request handling' do
    it 'does verify integration' do
      params = {
        endpoint:   endpoint,
        api_token:  token,
        verify_ssl: verify_ssl
      }
      authenticated_as(agent)
      post '/api/v1/integration/gitlab/verify', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['error']).to eq('User authorization failed.')

      authenticated_as(admin)
      instance = instance_double(GitLab)
      expect(GitLab).to receive(:new).with(endpoint: endpoint, api_token: token, verify_ssl: verify_ssl).and_return instance
      expect(instance).to receive(:verify!).and_return(true)

      post '/api/v1/integration/gitlab/verify', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['result']).to eq('ok')
    end

    context 'with activated gitlab integration' do
      before do
        Setting.set('gitlab_integration', true)
        Setting.set('gitlab_config', { 'endpoint' => ENV['GITLAB_ENDPOINT'], 'api_token' => ENV['GITLAB_APITOKEN'] })
      end

      it 'does query objects without ticket id' do
        params = {
          links: [ issue_link ],
        }
        authenticated_as(agent)
        instance = instance_double(GitLab)
        expect(GitLab).to receive(:new).and_return instance
        expect(instance).to receive(:issues_by_urls).and_return(
          {
            issues:           [issue_data],
            url_replacements: []
          }
        )

        post '/api/v1/integration/gitlab', params: params, as: :json
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response).not_to be_blank
        expect(json_response['result']).to eq('ok')
        expect(json_response['response']).to eq([issue_data.deep_stringify_keys])
      end
    end

    it 'does save ticket issues' do
      ticket = create(:ticket, group: Group.first)

      params = {
        ticket_id:   ticket.id,
        issue_links: [ issue_link ],
      }
      authenticated_as(agent)
      post '/api/v1/integration/gitlab_ticket_update', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['result']).to eq('ok')

      expect(ticket.reload.preferences[:gitlab][:issue_links]).to eq(params[:issue_links])
    end

    context 'with SSL verification support' do
      describe '.verify' do
        def request
          params = {
            endpoint:   endpoint,
            api_token:  token,
            verify_ssl: verify_ssl,
          }
          authenticated_as(admin)
          post '/api/v1/integration/gitlab/verify', params: params, as: :json
          expect(response).to have_http_status(:ok)
        end

        it 'does verify SSL' do
          allow(UserAgent).to receive(:get_http)
          request
          expect(UserAgent).to have_received(:get_http).with(URI::HTTPS, hash_including(verify_ssl: true)).once
        end

        context 'with SSL verification turned off' do
          let(:verify_ssl) { false }

          it 'does not verify SSL' do
            allow(UserAgent).to receive(:get_http)
            request
            expect(UserAgent).to have_received(:get_http).with(URI::HTTPS, hash_including(verify_ssl: false)).once
          end
        end
      end

      describe '.query' do
        before do
          Setting.set('gitlab_integration', true)
          Setting.set('gitlab_config', {
                        endpoint:   endpoint,
                        api_token:  token,
                        verify_ssl: verify_ssl,
                      })
        end

        def request
          params = {
            links: [ issue_link ],
          }
          authenticated_as(agent)
          post '/api/v1/integration/gitlab', params: params, as: :json
          expect(response).to have_http_status(:ok)
        end

        it 'does verify SSL' do
          allow(UserAgent).to receive(:get_http)
          request
          expect(UserAgent).to have_received(:get_http).with(URI::HTTPS, hash_including(verify_ssl: true)).once
        end

        context 'with SSL verification turned off' do
          let(:verify_ssl) { false }

          it 'does not verify SSL' do
            allow(UserAgent).to receive(:get_http)
            request
            expect(UserAgent).to have_received(:get_http).with(URI::HTTPS, hash_including(verify_ssl: false)).once
          end
        end
      end
    end
  end
end

# rubocop:enable RSpec/StubbedMock,RSpec/MessageSpies
