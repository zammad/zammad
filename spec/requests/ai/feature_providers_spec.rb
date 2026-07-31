# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AI::FeatureProvider', :aggregate_failures, authenticated_as: :user, type: :request do
  let(:user) { create(:admin) }

  let(:conn_a) { create(:ai_provider_connection, name: 'conn-a', provider: 'open_ai') }
  let(:conn_b) { create(:ai_provider_connection, name: 'conn-b', provider: 'anthropic') }

  describe '#show' do
    it 'returns the requested feature provider row' do
      fp = create(:ai_feature_provider, identifier: 'text_tool', provider_connection: conn_a)

      get "/api/v1/ai/feature_providers/#{fp.id}", as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('id' => fp.id, 'identifier' => 'text_tool')
    end
  end

  describe '#index' do
    it 'returns existing feature provider rows' do
      fp = create(:ai_feature_provider, identifier: 'ticket_summarize', provider_connection: conn_a)

      get '/api/v1/ai/feature_providers', as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include(include('id' => fp.id, 'identifier' => 'ticket_summarize'))
    end
  end

  describe '#create' do
    it 'creates a new feature provider override' do
      post '/api/v1/ai/feature_providers',
           params: { identifier: 'text_tool', provider_connection_id: conn_a.id },
           as:     :json

      expect(response).to have_http_status(:created)
      expect(json_response).to include('identifier' => 'text_tool', 'provider_connection_id' => conn_a.id)
    end

    it 'returns 422 for an unknown identifier' do
      post '/api/v1/ai/feature_providers',
           params: { identifier: 'does_not_exist', provider_connection_id: conn_a.id },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns 422 for a duplicate identifier' do
      create(:ai_feature_provider, identifier: 'text_tool', provider_connection: conn_a)

      post '/api/v1/ai/feature_providers',
           params: { identifier: 'text_tool', provider_connection_id: conn_b.id },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe '#update' do
    it 'updates the connection' do
      fp = create(:ai_feature_provider, identifier: 'text_tool', provider_connection: conn_a)

      put "/api/v1/ai/feature_providers/#{fp.id}",
          params: { provider_connection_id: conn_b.id },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(fp.reload.provider_connection_id).to eq(conn_b.id)
    end

    it 'ignores attempts to change the identifier' do
      fp = create(:ai_feature_provider, identifier: 'text_tool', provider_connection: conn_a)

      put "/api/v1/ai/feature_providers/#{fp.id}",
          params: { identifier: 'ticket_summarize', provider_connection_id: conn_a.id },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(fp.reload.identifier).to eq('text_tool')
    end
  end

  describe '#destroy' do
    it 'deletes the feature provider override' do
      fp = create(:ai_feature_provider, identifier: 'text_tool', provider_connection: conn_a)

      delete "/api/v1/ai/feature_providers/#{fp.id}", as: :json

      expect(response).to have_http_status(:ok)
      expect(AI::FeatureProvider.exists?(fp.id)).to be false
    end
  end

  describe 'permission' do
    let(:user) { create(:agent) }

    it 'returns 403 for authenticated non-admin users' do
      get '/api/v1/ai/feature_providers', as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end
