# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The per provider specs are tagged `integration` and need real credentials, hence they do not run
# in a regular pipeline - the embedding request of a provider that has no embedding model of its own
# is covered here without network access instead.
RSpec.describe AI::Provider, '#embeddings' do
  # The model used to be resolved from the adapter's DEFAULT_OPTIONS at request time, which made it
  # invisible in the admin UI and moved it under the admin's feet whenever the default was bumped.
  describe 'without a configured embedding model' do
    # Every embedding capable provider takes its model from the connection - except Zammad AI, whose
    # service serves a fixed one that an admin neither picks nor sees.
    let(:configs) do
      {
        'open_ai'        => { token: 'sk-123' },
        'mistral'        => { token: 'sk-123' },
        'ollama'         => { url: 'http://localhost:11434' },
        'custom_open_ai' => { url: 'https://example.com/v1' },
      }
    end

    before do
      allow(UserAgent).to receive(:post)
    end

    it 'covers every embedding capable provider' do
      supported = described_class.constants
        .map { |const| described_class.const_get(const) }
        .select { |klass| klass.is_a?(Class) && klass < described_class && klass.supports_embeddings? }
        .map { |klass| klass.name.demodulize.underscore }

      expect(supported).to match_array(configs.keys + ['zammad_ai'])
    end

    it 'raises instead of embedding against a model nobody chose', :aggregate_failures do
      configs.each do |provider, config|
        instance = described_class.by_name(provider).new(config:)

        expect { instance.embed(input: 'text') }
          .to raise_error(AI::Provider::RequestError, 'Missing embedding model in the provider configuration'),
              "#{provider} did not raise"
      end

      expect(UserAgent).not_to have_received(:post)
    end

    it 'embeds with the fixed model of a provider that has one', :aggregate_failures do
      allow(UserAgent).to receive(:post).and_return(
        UserAgent::Result.new(success: true, code: 200, data: [{ 'embeddings' => [[0.1]] }])
      )

      instance = AI::Provider::ZammadAI.new(config: { token: 'sk-123' })

      expect(instance.embed(input: 'text')).to eq([0.1])
      expect(UserAgent).to have_received(:post)
        .with(%r{/embed\z}, hash_including(llm: AI::Provider::ZammadAI::EMBEDDING_MODEL_FALLBACK), anything)
    end
  end

  describe '.recommended_embedding_model' do
    it 'has none by default' do
      expect(described_class.recommended_embedding_model).to be_nil
    end

    # What the dialog pre-selects, and what the migration backfilled a connection with.
    it 'reports the model to pre-select per provider', :aggregate_failures do
      expect(AI::Provider::OpenAI.recommended_embedding_model).to eq('text-embedding-3-small')
      expect(AI::Provider::Mistral.recommended_embedding_model).to eq('mistral-embed')
      expect(AI::Provider::Ollama.recommended_embedding_model).to eq('bge-m3')
    end

    # A custom endpoint serves whatever was deployed there, Anthropic/Azure AI cannot embed, and
    # Zammad AI's model is not configurable, so none of them has anything to pre-select.
    it 'has none where there is nothing to pre-select', :aggregate_failures do
      expect(AI::Provider::CustomOpenAI.recommended_embedding_model).to be_nil
      expect(AI::Provider::Anthropic.recommended_embedding_model).to be_nil
      expect(AI::Provider::Azure.recommended_embedding_model).to be_nil
      expect(AI::Provider::ZammadAI.recommended_embedding_model).to be_nil
    end
  end

  describe '.embedding_model_fallback' do
    it 'has none by default' do
      expect(described_class.embedding_model_fallback).to be_nil
    end

    it 'reports the fixed model of a provider whose model is not configurable' do
      expect(AI::Provider::ZammadAI.embedding_model_fallback).to eq('bge-m3')
    end

    # Their model comes from the connection, so a fallback would resurrect the silent resolution.
    it 'has none where the model is configured', :aggregate_failures do
      expect(AI::Provider::OpenAI.embedding_model_fallback).to be_nil
      expect(AI::Provider::Mistral.embedding_model_fallback).to be_nil
      expect(AI::Provider::Ollama.embedding_model_fallback).to be_nil
      expect(AI::Provider::CustomOpenAI.embedding_model_fallback).to be_nil
    end
  end

  describe 'with a custom OpenAI compatible provider' do
    subject(:ai_provider) { AI::Provider::CustomOpenAI.new(config:) }

    let(:config) { { url: 'https://example.com/v1', token: 'sk-123', embedding_model: 'text-embedding-3-small' } }

    def stub_post(response)
      allow(UserAgent).to receive(:post).and_return(response)
    end

    def embedding_response(vectors)
      UserAgent::Result.new(success: true, code: 200, data: { 'data' => vectors.map { |v| { 'embedding' => v } } })
    end

    it 'supports embeddings' do
      expect(AI::Provider::CustomOpenAI.supports_embeddings?).to be(true)
    end

    it 'returns the vector of a single input' do
      stub_post(embedding_response([[0.1, 0.2]]))

      expect(ai_provider.embed(input: 'text')).to eq([0.1, 0.2])
    end

    it 'returns one vector per input of a batch' do
      stub_post(embedding_response([[0.1], [0.2], [0.3]]))

      expect(ai_provider.bulk_embed(input: %w[one two three])).to eq([[0.1], [0.2], [0.3]])
    end

    it 'asks the endpoint for the configured embedding model' do
      stub_post(embedding_response([[0.1]]))

      ai_provider.embed(input: 'text')

      expect(UserAgent).to have_received(:post).with(
        'https://example.com/v1/embeddings',
        { model: 'text-embedding-3-small', input: 'text' },
        hash_including(bearer_token: 'sk-123'),
      )
    end

    # A compatible endpoint can answer 200 with a shape of its own making; that has to surface as
    # the mapped provider error, not as an internal one.
    it 'reports a payload without an embedding list', :aggregate_failures do
      [
        { 'embeddings' => [[0.1]] },
        { 'data' => 'not a list' },
        %w[not a hash],
      ].each do |payload|
        stub_post(UserAgent::Result.new(success: true, code: 200, data: payload))

        expect { ai_provider.embed(input: 'text') }
          .to raise_error(AI::Provider::ResponseError, 'The response could not be processed.')
      end
    end

    # Unlike the hosted providers, a custom endpoint has no embedding model to fall back to: its
    # model is whatever the admin deployed there. Asking without one would embed against the
    # endpoint's default, or fail with a message from the endpoint rather than about the config.
    context 'without a configured embedding model' do
      let(:config) { { url: 'https://example.com/v1' } }

      it 'raises RequestError instead of asking the endpoint', :aggregate_failures do
        allow(UserAgent).to receive(:post)

        expect { ai_provider.embed(input: 'text') }
          .to raise_error(AI::Provider::RequestError, 'Missing embedding model in the provider configuration')
        expect(UserAgent).not_to have_received(:post)
      end

      # A cleared dialog field arrives as '' and never reaches the options (see #initialize).
      context 'when the config field was cleared' do
        let(:config) { { url: 'https://example.com/v1', embedding_model: '' } }

        it 'raises RequestError' do
          expect { ai_provider.embed(input: 'text') }
            .to raise_error(AI::Provider::RequestError, 'Missing embedding model in the provider configuration')
        end
      end
    end

    context 'without a configured token' do
      let(:config) { { url: 'https://example.com/v1', embedding_model: 'text-embedding-3-small' } }

      # The target host might not require authentication.
      it 'sends no token' do
        stub_post(embedding_response([[0.1]]))

        ai_provider.embed(input: 'text')

        expect(UserAgent).to have_received(:post).with(anything, anything, hash_excluding(:bearer_token))
      end
    end

    it 'attributes the request to the connection' do
      connection = create(:ai_provider_connection)
      stub_post(embedding_response([[0.1]]))

      AI::Provider::CustomOpenAI.new(config:, related_object: connection).embed(input: 'text')

      expect(UserAgent).to have_received(:post)
        .with(anything, anything, hash_including(log: hash_including(related_object: connection)))
    end

    it 'maps a failing endpoint to the provider message' do
      stub_post(UserAgent::Result.new(success: false, code: 401))

      expect { ai_provider.embed(input: 'text') }
        .to raise_error(AI::Provider::ResponseError, 'Invalid API key - please check your configuration')
    end
  end
end
