# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Overviews', type: :request do

  let(:admin) do
    create(:admin)
  end

  describe 'request handling' do

    it 'does return no permissions' do
      params = {
        name:      'Overview2',
        link:      'my_overview',
        roles:     Role.where(name: 'Agent').pluck(:name),
        condition: {
          'ticket.state_id' => {
            operator: 'is',
            value:    [1, 2, 3],
          },
        },
        order:     {
          by:        'created_at',
          direction: 'DESC',
        },
        view:      {
          d:                 %w[title customer state created_at],
          s:                 %w[number title customer state created_at],
          m:                 %w[number title customer state created_at],
          view_mode_default: 's',
        },
      }

      agent = create(:agent, password: 'we need a password here')

      authenticated_as(agent)
      post '/api/v1/overviews', params: params, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Invalid BasicAuth credentials')
    end

    it 'does create overviews' do
      params = {
        name:      'Overview2',
        link:      'my_overview',
        roles:     Role.where(name: 'Agent').pluck(:name),
        condition: {
          'ticket.state_id' => {
            operator: 'is',
            value:    [1, 2, 3],
          },
        },
        order:     {
          by:        'created_at',
          direction: 'DESC',
        },
        view:      {
          d:                 %w[title customer state created_at],
          s:                 %w[number title customer state created_at],
          m:                 %w[number title customer state created_at],
          view_mode_default: 's',
        },
      }

      authenticated_as(admin)
      post '/api/v1/overviews', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['name']).to eq('Overview2')
      expect(json_response['link']).to eq('my_overview')

      post '/api/v1/overviews', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['name']).to eq('Overview2')
      expect(json_response['link']).to eq('my_overview_1')
    end

    it 'does set mass prio' do
      roles = Role.where(name: 'Agent')
      overview1 = Overview.create!(
        name:          'Overview1',
        link:          'my_overview',
        roles:         roles,
        condition:     {
          'ticket.state_id' => {
            operator: 'is',
            value:    [1, 2, 3],
          },
        },
        order:         {
          by:        'created_at',
          direction: 'DESC',
        },
        view:          {
          d:                 %w[title customer state created_at],
          s:                 %w[number title customer state created_at],
          m:                 %w[number title customer state created_at],
          view_mode_default: 's',
        },
        prio:          1,
        updated_by_id: 1,
        created_by_id: 1,
      )
      overview2 = Overview.create!(
        name:          'Overview2',
        link:          'my_overview',
        roles:         roles,
        condition:     {
          'ticket.state_id' => {
            operator: 'is',
            value:    [1, 2, 3],
          },
        },
        order:         {
          by:        'created_at',
          direction: 'DESC',
        },
        view:          {
          d:                 %w[title customer state created_at],
          s:                 %w[number title customer state created_at],
          m:                 %w[number title customer state created_at],
          view_mode_default: 's',
        },
        prio:          2,
        updated_by_id: 1,
        created_by_id: 1,
      )

      params = {
        prios: [
          [overview2.id, 1],
          [overview1.id, 2],
        ]
      }
      authenticated_as(admin)
      post '/api/v1/overviews_prio', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['success']).to eq(true)

      overview1.reload
      overview2.reload

      expect(overview1.prio).to eq(2)
      expect(overview2.prio).to eq(1)
    end

    it 'does create an overview with group_by direction' do

      params = {
        name:            'Overview2',
        link:            'my_overview',
        roles:           Role.where(name: 'Agent').pluck(:name),
        condition:       {
          'ticket.state_id' => {
            operator: 'is',
            value:    [1, 2, 3],
          },
        },
        order:           {
          by:        'created_at',
          direction: 'DESC',
        },
        group_by:        'priority',
        group_direction: 'ASC',
        view:            {
          d:                 %w[title customer state created_at],
          s:                 %w[number title customer state created_at],
          m:                 %w[number title customer state created_at],
          view_mode_default: 's',
        },
      }

      authenticated_as(admin)
      post '/api/v1/overviews', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['name']).to eq('Overview2')
      expect(json_response['link']).to eq('my_overview')
      expect(json_response['group_by']).to eq('priority')
      expect(json_response['group_direction']).to eq('ASC')
    end
  end
end
