# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'HTTP Logs endpoints', aggregate_failures: true, type: :request do

  let(:admin)    { create(:admin) }
  let(:customer) { create(:customer) }

  describe 'GET /api/v1/http_logs and /api/v1/http_logs/:facility' do

    context 'when admin has full permissions', authenticated_as: :admin do
      before do
        create(:http_log, facility: 'webhook')
        create(:http_log, facility: 'GitHub')
        create(:http_log, facility: 'cti')
      end

      it 'returns recent logs without facility' do
        get '/api/v1/http_logs', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response.size).to eq(3)
      end

      it 'returns only logs for the requested facility' do
        get '/api/v1/http_logs/cti', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response.pluck('facility').uniq).to eq(['cti'])
      end
    end

    context 'when admin has only overview permissions', authenticated_as: :admin do
      let(:admin_role)  { create(:role, permission_names: ['admin.overview']) }
      let(:admin) { create(:user, roles: [admin_role]) }

      before do
        create(:http_log, facility: 'webhook')
        create(:http_log, facility: 'GitHub')
      end

      it 'returns empty list without facility' do
        get '/api/v1/http_logs', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq([])
      end

      it 'returns empty list with facility' do
        get '/api/v1/http_logs/webhook', as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when admin has only webhook permissions', authenticated_as: :admin do
      let(:admin_role)  { create(:role, permission_names: ['admin.webhook']) }
      let(:admin) { create(:user, roles: [admin_role]) }

      before do
        create(:http_log, facility: 'webhook')
        create(:http_log, facility: 'GitHub')
      end

      it 'returns only the items with existing facility permissions' do
        get '/api/v1/http_logs', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response.size).to eq(1)
      end

      it 'returns facility items with correct permission' do
        get '/api/v1/http_logs/webhook', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response.pluck('facility').uniq).to eq(['webhook'])
      end
    end

    context 'when customer', authenticated_as: :customer do
      it 'forbids listing without facility' do
        get '/api/v1/http_logs', as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'forbids listing with facility' do
        get '/api/v1/http_logs/webhook', as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/http_logs' do
    let(:payload) { attributes_params_for(:http_log).merge(facility: 'webhook') }

    context 'when admin', authenticated_as: :admin do
      it 'creates a new http log' do
        expect do
          post '/api/v1/http_logs', params: payload, as: :json
        end.to change(HttpLog, :count).by(1)

        expect(HttpLog.last.facility).to eq('webhook')
      end
    end

    context 'when customer', authenticated_as: :customer do
      it 'forbids creating http logs' do
        post '/api/v1/http_logs', params: payload, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
