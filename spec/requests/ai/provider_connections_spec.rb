# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AI::ProviderConnection', :aggregate_failures, authenticated_as: :user, type: :request do
  let(:user) { create(:admin) }

  # Prevent real network calls from the provider_accessible validation.
  before do
    # OpenAI validates the config in check_temperature_support!, the other two in ping!.
    allow(AI::Provider::OpenAI).to receive(:check_temperature_support!).and_return(true)
    allow(AI::Provider::Anthropic).to receive(:ping!).and_return(nil)
    allow(AI::Provider::Ollama).to receive(:ping!).and_return(nil)
  end

  describe '#index' do
    it 'returns all provider connections' do
      create(:ai_provider_connection, name: 'conn-a', provider: 'open_ai')
      create(:ai_provider_connection, name: 'conn-b', provider: 'anthropic')

      get '/api/v1/ai/provider_connections', as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include(
        include('name' => 'conn-a'),
        include('name' => 'conn-b'),
      )
    end

    it 'masks secrets in the response' do
      create(:ai_provider_connection, name: 'secret-conn', provider: 'open_ai',
             config: { token: 'real-secret', model: 'gpt-4o' })

      get '/api/v1/ai/provider_connections', as: :json

      expect(response).to have_http_status(:ok)
      conn = json_response.find { |r| r['name'] == 'secret-conn' }
      expect(conn.dig('config', 'token')).to eq('**********')
      expect(conn.dig('config', 'model')).to eq('gpt-4o')
    end
  end

  describe '#show' do
    it 'returns the requested connection' do
      conn = create(:ai_provider_connection, name: 'my-conn')

      get "/api/v1/ai/provider_connections/#{conn.id}", as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('id' => conn.id, 'name' => 'my-conn')
    end
  end

  describe '#create' do
    it 'creates a new connection' do
      post '/api/v1/ai/provider_connections',
           params: { name: 'new-conn', provider: 'open_ai', config: { token: 'sk-123' } },
           as:     :json

      expect(response).to have_http_status(:created)
      expect(json_response).to include('name' => 'new-conn', 'provider' => 'open_ai')
    end

    it 'stores the detected temperature support' do
      post '/api/v1/ai/provider_connections',
           params: { name: 'new-conn', provider: 'open_ai', config: { token: 'sk-123' } },
           as:     :json

      expect(response).to have_http_status(:created)
      expect(AI::ProviderConnection.find_by(name: 'new-conn').config)
        .to include('model_temperature_support' => true)
    end

    it 'handles a submitted but empty config' do
      post '/api/v1/ai/provider_connections',
           params: { name: 'no-config-conn', provider: 'open_ai', config: nil },
           as:     :json

      expect(response).to have_http_status(:created)
      expect(AI::ProviderConnection.find_by(name: 'no-config-conn').config)
        .to eq('model_temperature_support' => true)
    end

    it 'creates a connection named "default"' do
      post '/api/v1/ai/provider_connections',
           params: { name: 'default', provider: 'open_ai', config: { token: 'sk-123' } },
           as:     :json

      expect(response).to have_http_status(:created)
      expect(json_response).to include('name' => 'default')
    end

    it 'returns 422 when provider_accessible fails' do
      allow(AI::Provider::OpenAI).to receive(:check_temperature_support!).and_raise(AI::Provider::ResponseError, 'Connection refused')

      post '/api/v1/ai/provider_connections',
           params: { name: 'bad-conn', provider: 'open_ai', config: { token: 'sk-bad' } },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to include('Connection refused')
    end

    it 'returns 422 when provider_accessible fails for a payload carrying the frontend client-side id' do
      allow(AI::Provider::OpenAI).to receive(:check_temperature_support!).and_raise(AI::Provider::ResponseError, 'Connection refused')

      post '/api/v1/ai/provider_connections',
           params: { id: 'c-0', name: 'bad-conn', provider: 'open_ai', config: { token: 'sk-bad' } },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
      # The point is that the test ran at all, so pin the provider error rather than any 422.
      expect(json_response['error']).to include('Connection refused')
      expect(AI::ProviderConnection.exists?(name: 'bad-conn')).to be false
    end

    it 'returns 422 for a malformed URL in the config' do
      allow(AI::Provider::OpenAI).to receive(:check_temperature_support!).and_raise(URI::InvalidURIError, 'bad URI')

      post '/api/v1/ai/provider_connections',
           params: { name: 'bad-conn', provider: 'open_ai', config: { token: 'sk-bad' } },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to include('bad URI')
    end

    it 'does not mask an unexpected internal error as a provider error' do
      allow(AI::Provider::OpenAI).to receive(:check_temperature_support!).and_raise(NoMethodError, 'Zammad-side bug')

      post '/api/v1/ai/provider_connections',
           params: { name: 'bad-conn', provider: 'open_ai', config: { token: 'sk-bad' } },
           as:     :json

      expect(response).to have_http_status(:internal_server_error)
    end

    it 'returns 422 when creating a Zammad AI connection on SaaS' do
      Setting.set('system_online_service', true)
      allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(nil)

      post '/api/v1/ai/provider_connections',
           params: { name: 'zammad-ai-conn', provider: 'zammad_ai', config: { token: 'sk-123' } },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(AI::ProviderConnection.exists?(name: 'zammad-ai-conn')).to be false
    end

    it 'creates a Zammad AI connection on self-hosted systems' do
      allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(nil)

      post '/api/v1/ai/provider_connections',
           params: { name: 'zammad-ai-conn', provider: 'zammad_ai', config: { token: 'sk-123' } },
           as:     :json

      expect(response).to have_http_status(:created)
    end
  end

  describe '#update' do
    it 'updates the name without re-testing when config is unchanged' do
      conn = create(:ai_provider_connection, name: 'old-name')

      allow(AI::Provider::OpenAI).to receive(:check_temperature_support!) # should not be called

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'new-name', provider: 'open_ai' },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('name' => 'new-name')
      expect(AI::Provider::OpenAI).not_to have_received(:check_temperature_support!)
    end

    # How :id is read decides create vs update, so pin the boundary: a missing record must not turn
    # into a silent success.
    it 'returns 404 for a nonexistent connection' do
      put '/api/v1/ai/provider_connections/999999',
          params: { name: 'conn', provider: 'open_ai', config: { token: 'x' } },
          as:     :json

      expect(response).to have_http_status(:not_found)
    end

    # Clearing the config is a change like any other, so it must not slip past the connection test
    # the way an omitted config does.
    it 'tests an explicitly emptied config instead of skipping it' do
      conn = create(:ai_provider_connection, name: 'conn', provider: 'open_ai', config: { token: 'old-token' })

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'conn', provider: 'open_ai', config: {} },
          as:     :json

      expect(AI::Provider::OpenAI).to have_received(:check_temperature_support!).with({}, related_object: conn)
    end

    it 'validates the retained config against the new provider when only the provider changes' do
      conn = create(:ai_provider_connection, name: 'conn', provider: 'open_ai', config: { token: 'kept-token' })

      pinged_config = nil
      allow(AI::Provider::Anthropic).to receive(:ping!) { |config| pinged_config = config }

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'conn', provider: 'anthropic' },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(pinged_config).to eq(token: 'kept-token')
    end

    it 'stores the detected temperature support when only the provider changes' do
      conn = create(:ai_provider_connection, name: 'conn', provider: 'open_ai',
                    config: { token: 'kept-token', model_temperature_support: false })

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'conn', provider: 'ollama' },
          as:     :json

      expect(response).to have_http_status(:ok)
      # No config is submitted here, so the flag detected for the new provider has to be merged
      # into the retained config instead of leaving the previous provider's value in place.
      expect(conn.reload.config)
        .to include('token' => 'kept-token', 'model_temperature_support' => true)
    end

    it 'preserves existing token when submitted as the mask sentinel' do
      conn = create(:ai_provider_connection, name: 'conn', provider: 'open_ai',
                    config: { token: 'original-token' })

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'conn', provider: 'open_ai',
                    config: { token: '**********', model: 'gpt-4.1' } },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(conn.reload.config['token']).to eq('original-token')
    end

    it 'updates the token when a new value is provided' do
      conn = create(:ai_provider_connection, name: 'conn', provider: 'open_ai',
                    config: { token: 'old-token' })

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'conn', provider: 'open_ai', config: { token: 'new-token' } },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(conn.reload.config['token']).to eq('new-token')
    end

    it 'validates the config that will be stored, not a mix of old and new values' do
      conn = create(:ai_provider_connection, name: 'conn', provider: 'open_ai',
                    config: { token: 'old-token', model: 'gpt-4o' })

      tested_config = nil
      allow(AI::Provider::OpenAI).to receive(:check_temperature_support!) { |config| tested_config = config }

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'conn', provider: 'open_ai',
                    config: { token: '**********', model: '' } },
          as:     :json

      expect(response).to have_http_status(:ok)
      # The mask sentinel is restored from the stored token; the cleared model is dropped
      # from the tested config just like the model drops it on save.
      expect(tested_config).to eq(token: 'old-token')
      expect(conn.reload.config).not_to have_key('model')
    end

    # An admin debugging an existing connection needs the failed test request in the log to name it.
    it 'attributes the test request to the connection being updated' do
      conn = create(:ai_provider_connection, name: 'conn', provider: 'open_ai', config: { token: 'old-token' })

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'conn', provider: 'open_ai', config: { token: 'new-token' } },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(AI::Provider::OpenAI).to have_received(:check_temperature_support!)
        .with({ token: 'new-token' }, related_object: conn)
    end

    it 'updates the default chat connection like any other' do
      conn = create(:ai_provider_connection, :default_chat)

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'default', provider: 'open_ai', config: { token: 'sk-new' } },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(conn.reload.config['token']).to eq('sk-new')
    end

    it 'returns 422 when switching an existing connection to Zammad AI on SaaS' do
      Setting.set('system_online_service', true)
      conn = create(:ai_provider_connection, name: 'conn', provider: 'open_ai')
      allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(nil)

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'conn', provider: 'zammad_ai', config: {} },
          as:     :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(conn.reload.provider).to eq('open_ai')
    end

    it 'returns 422 when switching the provisioned Zammad AI connection away from it on SaaS' do
      Setting.set('system_online_service', true)
      conn = build(:ai_provider_connection, name: 'zammad-ai-conn', provider: 'zammad_ai').tap { |c| c.save(validate: false) }

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'zammad-ai-conn', provider: 'open_ai', config: { token: 'sk-new' } },
          as:     :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(conn.reload.provider).to eq('zammad_ai')
    end
  end

  describe '#search' do
    it 'searches for provider connections' do
      create(:ai_provider_connection, name: 'searchable-conn')
      create(:ai_provider_connection, name: 'other-conn')

      get '/api/v1/ai/provider_connections/search', params: { query: 'searchable' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to contain_exactly(include('name' => 'searchable-conn'))
    end

    it 'searches by provider' do
      create(:ai_provider_connection, name: 'conn-a', provider: 'anthropic')
      create(:ai_provider_connection, name: 'conn-b', provider: 'open_ai')

      get '/api/v1/ai/provider_connections/search', params: { query: 'anthropic' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to contain_exactly(include('name' => 'conn-a'))
    end

    # The admin table fetches with full=true, which renders assets instead of plain
    # attributes - secrets must be masked there just like in #index.
    it 'masks secrets in the full response used by the admin table' do
      conn = create(:ai_provider_connection, name: 'secret-conn', config: { token: 'real-secret', model: 'gpt-4o' })

      get '/api/v1/ai/provider_connections/search',
          params: { query: 'secret-conn', full: true, sort_by: 'name, id', order_by: 'ASC, ASC' },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(json_response['record_ids']).to eq([conn.id])
      expect(json_response.dig('assets', 'AIProviderConnection', conn.id.to_s, 'config'))
        .to include('token' => '**********', 'model' => 'gpt-4o')
    end
  end

  describe '#set_default' do
    it 'assigns the default embedding flag on an embedding-capable connection' do
      conn = create(:ai_provider_connection, provider: 'open_ai')

      put "/api/v1/ai/provider_connections/#{conn.id}/set_default",
          params: { default: 'embedding', enabled: true },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(conn.reload.default_embedding?).to be true
    end

    it 'supports disabling of the default provider' do
      conn = create(:ai_provider_connection, :default_embedding, provider: 'open_ai')

      expect(conn.default_embedding?).to be true

      put "/api/v1/ai/provider_connections/#{conn.id}/set_default",
          params: { default: 'embedding', enabled: false },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(conn.reload.default_embedding?).to be false
    end

    it 'supports omitting of the enabled parameter' do
      conn = create(:ai_provider_connection, provider: 'open_ai')

      put "/api/v1/ai/provider_connections/#{conn.id}/set_default",
          params: { default: 'embedding' },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(conn.reload.default_embedding?).to be true
    end

    it 'rejects the default embedding flag on a provider without embedding support' do
      conn = create(:ai_provider_connection, provider: 'anthropic')

      put "/api/v1/ai/provider_connections/#{conn.id}/set_default",
          params: { default: 'embedding', enabled: true },
          as:     :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(conn.reload.default_embedding?).to be false
    end

    it 'does not run the provider ping' do
      conn = create(:ai_provider_connection)

      allow(AI::Provider::OpenAI).to receive(:check_temperature_support!).and_raise('should not be called')

      put "/api/v1/ai/provider_connections/#{conn.id}/set_default",
          params: { default: 'ocr', enabled: true },
          as:     :json

      expect(response).to have_http_status(:ok)
    end

    it 'returns 422 for an unknown default purpose instead of an internal error' do
      conn = create(:ai_provider_connection)

      put "/api/v1/ai/provider_connections/#{conn.id}/set_default",
          params: { default: 'nonexisting', enabled: true },
          as:     :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns 422 when no default purpose is given' do
      conn = create(:ai_provider_connection)

      put "/api/v1/ai/provider_connections/#{conn.id}/set_default",
          params: { enabled: true },
          as:     :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe '#destroy' do
    it 'deletes a connection not in use' do
      conn = create(:ai_provider_connection, name: 'deletable')

      delete "/api/v1/ai/provider_connections/#{conn.id}", as: :json

      expect(response).to have_http_status(:ok)
      expect(AI::ProviderConnection.exists?(conn.id)).to be false
    end

    it 'returns 422 when deleting the protected Zammad AI connection on SaaS' do
      Setting.set('system_online_service', true)
      # Simulates the platform provisioning this connection outside the admin API.
      conn = build(:ai_provider_connection, provider: 'zammad_ai').tap { |c| c.save(validate: false) }

      delete "/api/v1/ai/provider_connections/#{conn.id}", as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(AI::ProviderConnection.exists?(conn.id)).to be true
    end

    it 'deletes the connection and its feature providers when in use' do
      conn             = create(:ai_provider_connection)
      feature_provider = create(:ai_feature_provider, provider_connection: conn)

      delete "/api/v1/ai/provider_connections/#{conn.id}", as: :json

      expect(response).to have_http_status(:ok)
      expect(AI::ProviderConnection.exists?(conn.id)).to be false
      expect(AI::FeatureProvider.exists?(feature_provider.id)).to be false
    end
  end

  describe 'permission' do
    let(:user) { create(:agent) }

    it 'returns 403 for authenticated non-admin users' do
      get '/api/v1/ai/provider_connections', as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end
