# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::ProviderConnection::ResolveEmbeddingMetadata do
  describe '#execute' do
    def success_response(data)
      UserAgent::Result.new(success: true, code: 200, data:)
    end

    def failed_response(code)
      UserAgent::Result.new(success: false, code:)
    end

    context 'with Ollama' do
      let(:config) { { 'url' => 'http://localhost:11434' } }

      def resolve(model)
        described_class.execute(provider: 'ollama', model:, incoming_config: config)
      end

      # /api/show reports both values, so nothing has to come from the known defaults.
      it 'resolves both values from the endpoint' do
        allow(UserAgent).to receive(:post).and_return(success_response({
                                                                         'model_info' => {
                                                                           'general.architecture'  => 'bert',
                                                                           'bert.embedding_length' => 4096,
                                                                           'bert.context_length'   => 16_384,
                                                                         },
                                                                       }))

        expect(resolve('bge-m3:latest')).to eq(embedding_size: 4096, embedding_input_limit: 16_384)
      end

      it 'asks /api/show for the model, attributed to the connection' do
        connection = create(:ai_provider_connection)
        allow(UserAgent).to receive(:post).and_return(success_response({}))

        described_class.execute(provider: 'ollama', model: 'bge-m3', incoming_config: config, related_object: connection)

        expect(UserAgent).to have_received(:post).with(
          %r{/api/show\z},
          { model: 'bge-m3' },
          hash_including(log: hash_including(related_object: connection, log_only_on_error: true)),
        )
      end

      # An endpoint too old to serve model_info answers with something else entirely.
      it 'falls back to the known defaults, resolving the model behind the tag' do
        allow(UserAgent).to receive(:post).and_return(success_response({ 'model_info' => 'llama' }))

        expect(resolve('bge-m3:latest')).to eq(embedding_size: 1024, embedding_input_limit: 8192)
      end

      # Not every endpoint behind the configured URL is an Ollama: a proxy or a different API may
      # answer the POST with a JSON array, which must not raise out of the dialog.
      it 'falls back to the known defaults when the endpoint answers with an array' do
        allow(UserAgent).to receive(:post).and_return(success_response([{ 'model_info' => { 'bert.embedding_length' => 4096 } }]))

        expect(resolve('bge-m3:latest')).to eq(embedding_size: 1024, embedding_input_limit: 8192)
      end

      it 'ignores reported values that are not whole numbers' do
        allow(UserAgent).to receive(:post).and_return(success_response({
                                                                         'model_info' => { 'bert.embedding_length' => '4096', 'bert.context_length' => 'many' },
                                                                       }))

        expect(resolve('bge-m3')).to eq(embedding_size: 1024, embedding_input_limit: 8192)
      end

      # Best effort: the credentials were already validated by the time the dialog asks for
      # metadata, and the known defaults can still answer what the request could not.
      it 'falls back to the known defaults when the metadata request fails' do
        allow(UserAgent).to receive(:post).and_return(failed_response(500))

        expect(resolve('bge-m3')).to eq(embedding_size: 1024, embedding_input_limit: 8192)
      end

      # A malformed URL raises out of UserAgent before its own rescue, which would take the dialog
      # down over a value the known defaults have anyway.
      it 'falls back to the known defaults for a malformed URL' do
        allow(UserAgent).to receive(:post).and_raise(URI::InvalidURIError, 'bad URI')

        expect(resolve('bge-m3')).to eq(embedding_size: 1024, embedding_input_limit: 8192)
      end
    end

    # Mistral serves per-model metadata only through its listing (max_context_length), and those
    # values already travel in the listing descriptors the dialog fetched for its dropdown -
    # repeating that request here would double it for every model picked. So a Mistral model is
    # answered from the known defaults alone, without a request.
    context 'with Mistral' do
      it 'resolves a known model from the shared defaults without any request', :aggregate_failures do
        allow(UserAgent).to receive(:get)
        allow(UserAgent).to receive(:post)

        result = described_class.execute(provider: 'mistral', model: 'mistral-embed', incoming_config: { 'token' => 'sk-123' })

        expect(result).to eq(embedding_size: 1024, embedding_input_limit: 8192)
        expect(UserAgent).not_to have_received(:get)
        expect(UserAgent).not_to have_received(:post)
      end
    end

    context 'with a provider that reports no metadata (OpenAI)' do
      def resolve(model)
        described_class.execute(provider: 'open_ai', model:, incoming_config: { 'token' => 'sk-123' })
      end

      it 'resolves a known model from the shared defaults without any request', :aggregate_failures do
        allow(UserAgent).to receive(:get)
        allow(UserAgent).to receive(:post)

        expect(resolve('text-embedding-3-large')).to eq(embedding_size: 3072, embedding_input_limit: 8191)

        expect(UserAgent).not_to have_received(:get)
        expect(UserAgent).not_to have_received(:post)
      end

      # nil is the signal for the dialog to require a manual value instead.
      it 'answers nil for a model no source knows' do
        expect(resolve('my-custom-embedder')).to eq(embedding_size: nil, embedding_input_limit: nil)
      end
    end

    # The point of the shared table of known defaults: the same model resolves the same
    # regardless of where it is served.
    it 'resolves a known model behind a custom OpenAI compatible endpoint' do
      result = described_class.execute(provider: 'custom_open_ai', model: 'bge-m3', incoming_config: { 'url' => 'http://localhost:1234/v1' })

      expect(result).to eq(embedding_size: 1024, embedding_input_limit: 8192)
    end

    it 'resolves against the config that will be stored: mask sentinels restored, blanks dropped' do
      allow(AI::Provider::Ollama).to receive(:embedding_model_metadata).and_return({})

      described_class.execute(
        provider:        'ollama',
        model:           'bge-m3',
        incoming_config: { 'token' => SensitiveParamsHelper::SENSITIVE_MASK, 'url' => 'http://localhost:11434', 'model' => '' },
        existing_config: { 'token' => 'real-token' },
      )

      expect(AI::Provider::Ollama).to have_received(:embedding_model_metadata)
        .with({ token: 'real-token', url: 'http://localhost:11434' }, 'bge-m3', related_object: nil)
    end

    it 'raises for an unknown provider' do
      expect { described_class.execute(provider: 'does_not_exist', model: 'bge-m3') }
        .to raise_error(Exceptions::UnprocessableContent, 'Unknown provider')
    end

    it 'raises without a provider' do
      expect { described_class.execute(provider: nil, model: 'bge-m3') }
        .to raise_error(Exceptions::UnprocessableContent, 'Unknown provider')
    end

    it 'raises for a provider without embedding support' do
      expect { described_class.execute(provider: 'anthropic', model: 'bge-m3') }
        .to raise_error(Exceptions::UnprocessableContent, %r{does not support embeddings})
    end

    it 'raises without a model' do
      expect { described_class.execute(provider: 'ollama', model: '', incoming_config: { 'url' => 'http://localhost:11434' }) }
        .to raise_error(Exceptions::UnprocessableContent, %r{Missing embedding model})
    end
  end
end
