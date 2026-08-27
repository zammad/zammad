# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AI::ProviderConnection', :aggregate_failures, authenticated_as: :user, type: :request do
  let(:user) { create(:admin) }

  # Prevent real network calls from the provider_accessible validation.
  before do
    # OpenAI and Anthropic validate the config in check_temperature_support!, Ollama in ping!.
    allow(AI::Provider::OpenAI).to receive(:check_temperature_support!).and_return(true)
    allow(AI::Provider::Anthropic).to receive(:check_temperature_support!).and_return(true)
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
      # The first connection is seeded as the embedding one, which names the recommended model.
      expect(AI::ProviderConnection.find_by(name: 'no-config-conn').config)
        .to eq('model_temperature_support' => true, 'embedding_model' => AI::Provider::OpenAI.recommended_embedding_model)
    end

    it 'creates a connection named "default"' do
      post '/api/v1/ai/provider_connections',
           params: { name: 'default', provider: 'open_ai', config: { token: 'sk-123' } },
           as:     :json

      expect(response).to have_http_status(:created)
      expect(json_response).to include('name' => 'default')
    end

    # The dialog constrains both fields, so this is the way an unusable one would get in - and it
    # would only fail once indexing runs, naming anything but the connection that holds it.
    it 'returns 422 for a non-positive embedding dimension', :aggregate_failures do
      post '/api/v1/ai/provider_connections',
           params: { name: 'bad-metadata', provider: 'open_ai',
                     config: { token: 'sk-123', embedding_model: 'text-embedding-3-small', embedding_size: 0 } },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to include('embedding dimensions must be a positive number')
      expect(AI::ProviderConnection.exists?(name: 'bad-metadata')).to be false
    end

    it 'returns 422 for a negative embedding input limit', :aggregate_failures do
      post '/api/v1/ai/provider_connections',
           params: { name: 'bad-metadata', provider: 'open_ai',
                     config: { token: 'sk-123', embedding_model: 'text-embedding-3-small', embedding_input_limit: -1 } },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to include('context window size must be a positive number')
      expect(AI::ProviderConnection.exists?(name: 'bad-metadata')).to be false
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

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'conn', provider: 'anthropic' },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(AI::Provider::Anthropic).to have_received(:check_temperature_support!)
        .with({ token: 'kept-token', embedding_model: 'text-embedding-3-small' }, related_object: conn)
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

      # The embedding model travels along, because this connection serves embeddings and a config
      # that stops naming one is rejected - which is what the dialog submits too.
      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'conn', provider: 'open_ai',
                    config: { token: '**********', model: 'gpt-4.1', embedding_model: 'text-embedding-3-small' } },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(conn.reload.config['token']).to eq('original-token')
    end

    it 'updates the token when a new value is provided' do
      conn = create(:ai_provider_connection, name: 'conn', provider: 'open_ai',
                    config: { token: 'old-token' })

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'conn', provider: 'open_ai',
                    config: { token: 'new-token', embedding_model: 'text-embedding-3-small' } },
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
                    config: { token: '**********', model: '', embedding_model: 'text-embedding-3-small' } },
          as:     :json

      expect(response).to have_http_status(:ok)
      # The mask sentinel is restored from the stored token; the cleared model is dropped
      # from the tested config just like the model drops it on save.
      expect(tested_config).to eq(token: 'old-token', embedding_model: 'text-embedding-3-small')
      expect(conn.reload.config).not_to have_key('model')
    end

    # An admin debugging an existing connection needs the failed test request in the log to name it.
    it 'attributes the test request to the connection being updated' do
      conn = create(:ai_provider_connection, name: 'conn', provider: 'open_ai', config: { token: 'old-token' })

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'conn', provider: 'open_ai',
                    config: { token: 'new-token', embedding_model: 'text-embedding-3-small' } },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(AI::Provider::OpenAI).to have_received(:check_temperature_support!)
        .with({ token: 'new-token', embedding_model: 'text-embedding-3-small' }, related_object: conn)
    end

    it 'updates the default chat connection like any other' do
      conn = create(:ai_provider_connection, :default_chat)

      put "/api/v1/ai/provider_connections/#{conn.id}",
          params: { name: 'default', provider: 'open_ai',
                    config: { token: 'sk-new', embedding_model: 'text-embedding-3-small' } },
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

    # Serving embeddings requires a named model, and this is the one path that can flag a connection
    # without going through the config dialog - so it names the recommendation itself.
    it 'names the recommended embedding model when flagging a connection that has none', :aggregate_failures do
      # The first connection is seeded as the embedding one; a later one names no model of its own.
      create(:ai_provider_connection, name: 'first', provider: 'open_ai', config: { token: 'a' })
      conn = create(:ai_provider_connection, name: 'other', provider: 'open_ai', config: { token: 'b' })

      put "/api/v1/ai/provider_connections/#{conn.id}/set_default",
          params: { default: 'embedding' },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(conn.reload.default_embedding?).to be true
      expect(conn.config['embedding_model']).to eq(AI::Provider::OpenAI.recommended_embedding_model)
    end

    # A custom endpoint serves whatever was deployed there, so there is nothing to name for it.
    it 'rejects the default embedding flag where no model can be named', :aggregate_failures do
      create(:ai_provider_connection, name: 'first', provider: 'open_ai', config: { token: 'a' })
      conn = create(:ai_provider_connection, name: 'custom', provider: 'custom_open_ai',
                    config: { url: 'https://example.com/v1', model: 'gpt-4o' })

      put "/api/v1/ai/provider_connections/#{conn.id}/set_default",
          params: { default: 'embedding' },
          as:     :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(conn.reload.default_embedding?).to be false
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

  describe '#models' do
    # Carrying both defaults of the provider, which is what the endpoint answers with them at all:
    # a default the listing does not have is withheld (see Service::AI::ProviderConnection::ListModels).
    let(:models) do
      [
        { id: 'gpt-4.1', capabilities: ['chat'] },
        { id: 'text-embedding-3-small', capabilities: ['embedding'] },
      ]
    end

    before do
      allow(AI::Provider::OpenAI).to receive(:models).and_return(models)
    end

    # The create dialog has no record yet, so it sends the credentials it collected.
    it 'lists the models for a submitted config' do
      post '/api/v1/ai/provider_connections/models',
           params: { provider: 'open_ai', config: { token: 'sk-123' } },
           as:     :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to eq(
        'models'                         => models.map(&:stringify_keys),
        # So the dialog can name what its empty model options fall back to, without a copy of the
        # adapter defaults in the AIProviders registry.
        'default_model'                  => AI::Provider::OpenAI.default_model,
        'recommended_embedding_model'    => AI::Provider::OpenAI.recommended_embedding_model,
        # So the dialog can fill both metadata fields for the empty option that stands for the
        # recommendation, without a request per opened dialog.
        'recommended_embedding_metadata' => {
          'embedding_size'        => AI::Provider::EMBEDDING_SIZES['text-embedding-3-small'],
          'embedding_input_limit' => AI::Provider::EMBEDDING_INPUT_LIMITS['text-embedding-3-small'],
        }
      )
      expect(AI::Provider::OpenAI).to have_received(:models).with({ token: 'sk-123' }, related_object: nil)
    end

    # The edit dialog renders the stored token as the mask sentinel, so listing must not send that
    # to the provider - the admin would have to re-type a working key for no reason.
    it 'lists with the stored token when the mask sentinel is submitted' do
      conn = create(:ai_provider_connection, provider: 'open_ai', config: { token: 'stored-token' })

      post "/api/v1/ai/provider_connections/#{conn.id}/models",
           params: { provider: 'open_ai', config: { token: '**********', model: 'gpt-4.1' } },
           as:     :json

      expect(response).to have_http_status(:ok)
      expect(AI::Provider::OpenAI).to have_received(:models)
        .with({ token: 'stored-token', model: 'gpt-4.1' }, related_object: conn)
    end

    it 'lists with the stored config when none is submitted' do
      conn = create(:ai_provider_connection, provider: 'open_ai', config: { token: 'stored-token' })

      post "/api/v1/ai/provider_connections/#{conn.id}/models", as: :json

      expect(AI::Provider::OpenAI).to have_received(:models)
        .with(hash_including(token: 'stored-token'), related_object: conn)
    end

    it 'returns 404 for a nonexistent connection' do
      post '/api/v1/ai/provider_connections/999999/models',
           params: { config: { token: 'sk-123' } },
           as:     :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 422 for an unknown provider' do
      post '/api/v1/ai/provider_connections/models',
           params: { provider: 'does_not_exist', config: { token: 'sk-123' } },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    # The namespace holds more than adapters, and such a key used to reach the listing as if it
    # were a provider - failing with an internal error instead of a rejected request.
    it 'returns 422 for a provider key that resolves to something other than an adapter' do
      post '/api/v1/ai/provider_connections/models',
           params: { provider: 'request_error', config: { token: 'sk-123' } },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns 422 for a config that is not a hash' do
      post '/api/v1/ai/provider_connections/models',
           params: { provider: 'open_ai', config: 'sk-123' },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    # The dialog never asks for such a provider - it has no model step - so this is a caller
    # error, not an empty listing.
    it 'rejects a provider without a model list' do
      post '/api/v1/ai/provider_connections/models',
           params: { provider: 'zammad_ai', config: { token: 'sk-123' } },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response).to include('error' => 'This provider does not support model listing.')
    end

    # 200, not 4xx: the request was fine, the listing was not - and the dialog shows the reason.
    it 'answers a failed listing with the provider message' do
      allow(AI::Provider::OpenAI).to receive(:models)
        .and_raise(AI::Provider::ResponseError, 'Invalid API key - please check your configuration')

      post '/api/v1/ai/provider_connections/models',
           params: { provider: 'open_ai', config: { token: 'sk-nope' } },
           as:     :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to eq(
        'models' => [], 'error' => 'Invalid API key - please check your configuration'
      )
    end

    # A malformed URL raises out of UserAgent before its own rescue, which would be a 500.
    it 'answers a malformed URL with the error instead of failing' do
      allow(AI::Provider::OpenAI).to receive(:models).and_raise(URI::InvalidURIError, 'bad URI')

      post '/api/v1/ai/provider_connections/models',
           params: { provider: 'open_ai', config: { token: 'sk-123', url: 'ht!tp://' } },
           as:     :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('error' => 'bad URI')
    end

    # The second call carries the config as the dialog resends it after a Back - grown by the
    # model fields. The listing depends on the credentials alone, so it still hits the cache.
    it 'answers a repeated call without asking the provider again, even as the config grows' do
      post '/api/v1/ai/provider_connections/models',
           params: { provider: 'open_ai', config: { token: 'sk-123' } },
           as:     :json

      post '/api/v1/ai/provider_connections/models',
           params: { provider: 'open_ai', config: { token: 'sk-123', model: 'gpt-4.1', embedding_model: 'text-embedding-3-small' } },
           as:     :json

      expect(response).to have_http_status(:ok)
      expect(AI::Provider::OpenAI).to have_received(:models).once
    end
  end

  describe '#embedding_metadata' do
    # Ollama is the provider serving per-model metadata outside its listing, so it is the one the
    # dialog asks - the others answer from the shared table of known defaults alone.
    before do
      allow(AI::Provider::Ollama).to receive(:embedding_model_metadata)
        .and_return({ embedding_size: 1024, embedding_input_limit: 8192 })
    end

    it 'resolves the metadata for a submitted config' do
      post '/api/v1/ai/provider_connections/embedding_metadata',
           params: { provider: 'ollama', model: 'bge-m3', config: { url: 'http://localhost:11434' } },
           as:     :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to eq('embedding_size' => 1024, 'embedding_input_limit' => 8192)
      expect(AI::Provider::Ollama).to have_received(:embedding_model_metadata)
        .with({ url: 'http://localhost:11434' }, 'bge-m3', related_object: nil)
    end

    it 'resolves with the stored token when the mask sentinel is submitted' do
      conn = create(:ai_provider_connection, provider: 'ollama', config: { url: 'http://localhost:11434', token: 'stored-token' })

      post "/api/v1/ai/provider_connections/#{conn.id}/embedding_metadata",
           params: { provider: 'ollama', model: 'bge-m3', config: { url: 'http://localhost:11434', token: '**********' } },
           as:     :json

      expect(response).to have_http_status(:ok)
      expect(AI::Provider::Ollama).to have_received(:embedding_model_metadata)
        .with({ url: 'http://localhost:11434', token: 'stored-token' }, 'bge-m3', related_object: conn)
    end

    # The provider knows nothing about it and neither does the shared table, so the dialog has to
    # ask the admin - null is the answer that says so.
    it 'answers null for a model no source knows' do
      allow(AI::Provider::Ollama).to receive(:embedding_model_metadata).and_return({})

      post '/api/v1/ai/provider_connections/embedding_metadata',
           params: { provider: 'ollama', model: 'homegrown-embed', config: { url: 'http://localhost:11434' } },
           as:     :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to eq('embedding_size' => nil, 'embedding_input_limit' => nil)
    end

    it 'falls back to the known defaults when the provider request fails' do
      allow(AI::Provider::Ollama).to receive(:embedding_model_metadata)
        .and_raise(AI::Provider::RequestError, 'connection refused')

      post '/api/v1/ai/provider_connections/embedding_metadata',
           params: { provider: 'ollama', model: 'bge-m3', config: { url: 'http://localhost:11434' } },
           as:     :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to eq(
        'embedding_size'        => AI::Provider::EMBEDDING_SIZES['bge-m3'],
        'embedding_input_limit' => AI::Provider::EMBEDDING_INPUT_LIMITS['bge-m3']
      )
    end

    it 'returns 404 for a nonexistent connection' do
      post '/api/v1/ai/provider_connections/999999/embedding_metadata',
           params: { provider: 'ollama', model: 'bge-m3' },
           as:     :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 422 for an unknown provider' do
      post '/api/v1/ai/provider_connections/embedding_metadata',
           params: { provider: 'does_not_exist', model: 'bge-m3' },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns 422 for a provider that cannot embed' do
      post '/api/v1/ai/provider_connections/embedding_metadata',
           params: { provider: 'anthropic', model: 'bge-m3', config: { token: 'sk-123' } },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns 422 when no model is given' do
      post '/api/v1/ai/provider_connections/embedding_metadata',
           params: { provider: 'ollama', config: { url: 'http://localhost:11434' } },
           as:     :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'permission' do
    let(:user) { create(:agent) }

    it 'returns 403 for authenticated non-admin users' do
      get '/api/v1/ai/provider_connections', as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 for the model listing of authenticated non-admin users' do
      post '/api/v1/ai/provider_connections/models',
           params: { provider: 'open_ai', config: { token: 'sk-123' } },
           as:     :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 for the embedding metadata of authenticated non-admin users' do
      post '/api/v1/ai/provider_connections/embedding_metadata',
           params: { provider: 'ollama', model: 'bge-m3', config: { url: 'http://localhost:11434' } },
           as:     :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'vector index rebuild response' do
    let(:connection) do
      create(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                          config:   { token: 'secret-token', embedding_model: 'text-embedding-3-small' })
    end
    let(:index_exists) { true }

    before do
      connection
      Setting.set('ai_provider', true)

      Service::AI::VectorDB::Embedding::Configuration.record_indexed(Service::AI::VectorDB::Embedding::Configuration.current) if index_exists

      Setting.set('vectordb_enabled', true)
    end

    describe '#create' do
      def create_connection(default_embedding: true)
        post '/api/v1/ai/provider_connections',
             params: { name:              'created-connection',
                       provider:          'open_ai',
                       default_embedding:,
                       config:            { token: 'secret-token', embedding_model: 'text-embedding-3-large' } },
             as:     :json
      end

      it 'creates a connection taking over semantic search and reports the background rebuild', :aggregate_failures do
        create_connection

        expect(response).to have_http_status(:created)
        expect(json_response).to include('vector_index_rebuild_started' => true)
        expect(AI::ProviderConnection.exists?(name: 'created-connection')).to be(true)
      end

      it 'creates a connection that serves nothing without reporting a rebuild' do
        create_connection(default_embedding: false)

        expect(response).to have_http_status(:created)
        expect(json_response).not_to include('vector_index_rebuild_started')
      end

      context 'when it is the first connection, taking the flag automatically' do
        before { AI::ProviderConnection.destroy_all }

        it 'creates it without reporting a rebuild while AI providers are disabled', :aggregate_failures do
          create_connection(default_embedding: false)

          expect(response).to have_http_status(:created)
          expect(json_response).not_to include('vector_index_rebuild_started')
        end
      end
    end

    describe '#update' do
      def edit_embedding_model
        put "/api/v1/ai/provider_connections/#{connection.id}",
            params: { config: { token: 'secret-token', embedding_model: 'text-embedding-3-large' } },
            as:     :json
      end

      it 'changes the embedding model and reports the background rebuild', :aggregate_failures do
        edit_embedding_model

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          'id'                           => connection.id,
          'name'                         => connection.name,
          'provider'                     => connection.provider,
          'config'                       => include('embedding_model' => 'text-embedding-3-large', 'token' => '**********'),
          'vector_index_rebuild_started' => true,
        )
        expect(connection.reload.config['embedding_model']).to eq('text-embedding-3-large')
      end

      it 'saves a change that leaves the embeddings alone without reporting a rebuild', :aggregate_failures do
        put "/api/v1/ai/provider_connections/#{connection.id}", params: { name: 'renamed' }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).not_to include('vector_index_rebuild_started')
        expect(connection.reload.name).to eq('renamed')
      end

      context 'when no index has been built yet' do
        let(:index_exists) { false }

        it 'reports the initial background build' do
          edit_embedding_model

          expect(response).to have_http_status(:ok)
          expect(json_response).to include('vector_index_rebuild_started' => true)
        end
      end

      context 'when the AI provider is switched off' do
        before { Setting.set('ai_provider', false) }

        it 'does not report a rebuild that cannot start', :aggregate_failures do
          edit_embedding_model

          expect(response).to have_http_status(:ok)
          expect(json_response).not_to include('vector_index_rebuild_started')
        end
      end

      context 'when the update hands semantic search over' do
        let(:candidate) { create(:ai_provider_connection, config: { token: 'a', embedding_model: 'text-embedding-3-large' }) }

        it 'hands it over and reports the background rebuild', :aggregate_failures do
          put "/api/v1/ai/provider_connections/#{candidate.id}", params: { default_embedding: true }, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response).to include('vector_index_rebuild_started' => true)
          expect(candidate.reload.default_embedding?).to be true
        end

        context 'when it runs on the same model' do
          let(:candidate) { create(:ai_provider_connection, config: { token: 'a', embedding_model: 'text-embedding-3-small' }) }

          it 'hands it over without reporting a rebuild', :aggregate_failures do
            put "/api/v1/ai/provider_connections/#{candidate.id}", params: { default_embedding: true }, as: :json

            expect(response).to have_http_status(:ok)
            expect(json_response).not_to include('vector_index_rebuild_started')
            expect(candidate.reload.default_embedding?).to be true
          end
        end
      end

      context 'with a connection that does not serve semantic search' do
        let(:other) { create(:ai_provider_connection, config: { token: 'a', embedding_model: 'text-embedding-3-small' }) }

        it 'saves without reporting a rebuild', :aggregate_failures do
          put "/api/v1/ai/provider_connections/#{other.id}",
              params: { config: { token: 'a', embedding_model: 'text-embedding-3-large' } },
              as:     :json

          expect(response).to have_http_status(:ok)
          expect(json_response).not_to include('vector_index_rebuild_started')
          expect(other.reload.config['embedding_model']).to eq('text-embedding-3-large')
        end
      end
    end

    describe '#set_default' do
      let(:candidate_model) { 'text-embedding-3-large' }
      let(:candidate)       { create(:ai_provider_connection, config: { token: 'a', embedding_model: candidate_model }) }

      def hand_over
        put "/api/v1/ai/provider_connections/#{candidate.id}/set_default",
            params: { default: 'embedding', enabled: true },
            as:     :json
      end

      it 'hands semantic search to another model and reports the background rebuild', :aggregate_failures do
        hand_over

        expect(response).to have_http_status(:ok)
        expect(json_response).to include('vector_index_rebuild_started' => true)
        expect(candidate.reload.default_embedding?).to be true
      end

      context 'when the connection it moves to runs on the same model' do
        let(:candidate_model) { 'text-embedding-3-small' }

        it 'hands it over without reporting a rebuild', :aggregate_failures do
          hand_over

          expect(response).to have_http_status(:ok)
          expect(json_response).not_to include('vector_index_rebuild_started')
          expect(candidate.reload.default_embedding?).to be true
        end
      end

      # Semantic search simply stops; the index is left where it is.
      it 'clears the default without reporting a rebuild', :aggregate_failures do
        put "/api/v1/ai/provider_connections/#{connection.id}/set_default",
            params: { default: 'embedding', enabled: false },
            as:     :json

        expect(response).to have_http_status(:ok)
        expect(json_response).not_to include('vector_index_rebuild_started')
        expect(connection.reload.default_embedding?).to be false
      end
    end
  end
end
