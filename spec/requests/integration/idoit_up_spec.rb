# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Integration::IdoitUp', type: :request do
  let(:agent)  { create(:agent, groups: Group.all) }
  let(:admin)  { create(:admin) }
  let(:ticket) { create(:ticket, group: Group.first) }

  let(:idoit_up_config) do
    {
      api_token:  'test-token',
      endpoint:   'https://idoit-up.example.com',
      verify_ssl: false,
    }
  end

  before do
    Setting.set('idoit_up_integration', true)
    Setting.set('idoit_up_config', idoit_up_config)
  end

  describe 'POST /api/v1/integration/idoit_up/verify' do
    context 'when authenticated as admin' do
      before { authenticated_as(admin) }

      it 'calls IdoitUp.verify and returns ok on success', :aggregate_failures do
        allow(IdoitUp).to receive(:verify).and_return({ 'result' => [] })

        post '/api/v1/integration/idoit_up/verify',
             params: { api_token: 'token', endpoint: 'https://example.com', client_id: '' },
             as:     :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['result']).to eq('ok')
      end

      it 'returns failed when IdoitUp.verify raises', :aggregate_failures do
        allow(IdoitUp).to receive(:verify).and_raise('connection refused')

        post '/api/v1/integration/idoit_up/verify',
             params: { api_token: 'bad', endpoint: 'https://example.com' },
             as:     :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['result']).to eq('failed')
        expect(response.parsed_body['message']).to include('connection refused')
      end
    end

    context 'when unauthenticated' do
      it 'is forbidden' do
        post '/api/v1/integration/idoit_up/verify', as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/integration/idoit_up' do
    before { authenticated_as(agent) }

    it 'queries objects and returns ok', :aggregate_failures do
      allow(IdoitUp).to receive(:query).and_return({ 'result' => [] })

      post '/api/v1/integration/idoit_up',
           params: { method: 'cmdb.objects', filter: { ids: ['abc'] } },
           as:     :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['result']).to eq('ok')
    end
  end

  describe 'POST /api/v1/integration/idoit_up_ticket_update' do
    before { authenticated_as(agent) }

    it 'stores object_ids on ticket preferences', :aggregate_failures do
      post '/api/v1/integration/idoit_up_ticket_update',
           params: { ticket_id: ticket.id, object_ids: %w[obj1 obj2] },
           as:     :json

      expect(response).to have_http_status(:ok)
      expect(ticket.reload.preferences[:idoit_up][:object_ids]).to eq(%w[obj1 obj2])
    end

    it 'deduplicates object_ids' do
      post '/api/v1/integration/idoit_up_ticket_update',
           params: { ticket_id: ticket.id, object_ids: %w[obj1 obj1 obj2] },
           as:     :json

      expect(ticket.reload.preferences[:idoit_up][:object_ids]).to eq(%w[obj1 obj2])
    end
  end
end
