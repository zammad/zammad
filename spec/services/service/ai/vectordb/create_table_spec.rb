# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::CreateTable do
  describe '.execute' do
    subject(:service_result) { described_class.execute }

    before do
      setup_ai_provider('open_ai')
    end

    it 'Create vector database table' do
      allow_any_instance_of(AI::VectorDB).to receive(:ping!)
      expect_any_instance_of(AI::VectorDB).to receive(:migrate).with(dimensions: 1536)

      service_result
    end
  end

  describe '#embedding_size' do
    subject(:embedding_size) { described_class.new.send(:embedding_size) }

    context 'when the provider config contains an embedding size' do
      before do
        setup_ai_provider('open_ai', embedding_size: 3072)
      end

      it 'returns the configured embedding size' do
        expect(embedding_size).to eq(3072)
      end
    end

    # The dialog submits a number, but the jsonb config keeps whatever an API update wrote there.
    context 'when the configured embedding size arrived as a string' do
      before do
        setup_ai_provider('open_ai', embedding_size: '3072')
      end

      it 'returns it as a number' do
        expect(embedding_size).to eq(3072)
      end
    end

    # AI::ProviderConnection rejects such a value on save, so this is legacy data - written into the
    # jsonb config before that validation existed. Hence the column write instead of an update.
    context 'when the configured embedding size is no number at all' do
      before do
        setup_ai_provider('open_ai', embedding_model: 'text-embedding-3-small')

        AI::ProviderConnection
          .find_by(name: 'default')
          .update_column(:config, { 'embedding_model' => 'text-embedding-3-small', 'embedding_size' => 'large' })
      end

      it 'returns the embedding size of the configured embedding model' do
        expect(embedding_size).to eq(1536)
      end
    end

    context 'when the configured embedding size is zero or less' do
      before do
        setup_ai_provider('open_ai', embedding_model: 'text-embedding-3-small')

        AI::ProviderConnection
          .find_by(name: 'default')
          .update_column(:config, { 'embedding_model' => 'text-embedding-3-small', 'embedding_size' => -1 })
      end

      it 'returns the embedding size of the configured embedding model' do
        expect(embedding_size).to eq(1536)
      end
    end

    context 'when the provider config contains an embedding model' do
      before do
        setup_ai_provider('ollama', url: 'http://localhost:11434', embedding_model: 'nomic-embed-text')
      end

      it 'returns the embedding size of the configured embedding model' do
        expect(embedding_size).to eq(768)
      end
    end

    # Zammad AI serves a fixed model that is not part of the config, so the dimension follows it.
    context 'when the provider serves a fixed embedding model' do
      before do
        setup_ai_provider('zammad_ai', token: 'sk-123')
      end

      it 'returns the embedding size of that model' do
        expect(embedding_size)
          .to eq(AI::Provider::ZammadAI::EMBEDDING_SIZES[AI::Provider::ZammadAI::EMBEDDING_MODEL_FALLBACK])
      end
    end

    # The model dropdown offers the id an endpoint reports, and Ollama reports name and tag. The
    # known sizes are keyed by name alone, so a verbatim lookup would fail table creation for a
    # model whose size is perfectly well known.
    context 'when the configured embedding model carries a tag' do
      before do
        setup_ai_provider('ollama', url: 'http://localhost:11434', embedding_model: 'bge-m3:latest')
      end

      it 'returns the embedding size of the model behind the tag' do
        expect(embedding_size).to eq(1024)
      end
    end

    # The known defaults are shared across the providers, so a common model resolves behind a
    # custom OpenAI compatible endpoint just like behind Ollama.
    context 'when a custom endpoint serves a commonly known embedding model' do
      before do
        setup_ai_provider('custom_open_ai', url: 'http://localhost:1234/v1', embedding_model: 'bge-m3')
      end

      it 'returns the embedding size of the shared known defaults' do
        expect(embedding_size).to eq(1024)
      end
    end

    context 'when the admin named no embedding model' do
      before do
        setup_ai_provider('mistral')
      end

      # Not resolved from the adapter at migration time: the connection carries the model the
      # embedding seeding named for it, which is the provider's recommendation.
      it 'returns the embedding size of the seeded recommendation' do
        expect(embedding_size).to eq(1024)
      end
    end

    # Reachable for a connection whose embedding model was cleared behind the dialog's back, e.g.
    # through the API. The dimension of the stored vectors must not be guessed for it.
    context 'when the embedding connection carries no model at all' do
      before do
        setup_ai_provider('mistral')
        AI::ProviderConnection.for_embeddings.update_column(:config, { 'token' => 'sk-123' })
      end

      it 'raises a migration error' do
        expect { embedding_size }.to raise_error(AI::VectorDB::MigrationError, %r{Missing embedding model})
      end
    end

    context 'when no connection is flagged for embedding (e.g. the only provider does not support it)' do
      before do
        setup_ai_provider('anthropic')
      end

      it 'raises a migration error' do
        expect { embedding_size }.to raise_error(AI::VectorDB::MigrationError, %r{no selected AI provider for embeddings})
      end
    end
  end
end
