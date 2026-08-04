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

    context 'when the provider config contains an embedding model' do
      before do
        setup_ai_provider('zammad_ai', embedding_model: 'nomic-embed-text')
      end

      it 'returns the embedding size of the configured embedding model' do
        expect(embedding_size).to eq(768)
      end
    end

    context 'when the provider config contains no embedding options' do
      before do
        setup_ai_provider('mistral')
      end

      it 'returns the embedding size of the default embedding model' do
        expect(embedding_size).to eq(1024)
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
