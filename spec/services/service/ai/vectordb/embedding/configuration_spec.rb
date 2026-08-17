# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Embedding::Configuration do
  let(:connection) do
    create(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                        config:   { token: 'secret-token', embedding_model: 'text-embedding-3-small' })
  end

  before do
    connection
    Setting.set('ai_provider', true)
  end

  describe '.of' do
    it 'describes what the connection embeds with' do
      expect(described_class.of(connection))
        .to eq(model: 'text-embedding-3-small', size: AI::Provider::EMBEDDING_SIZES['text-embedding-3-small'])
    end

    it 'resolves the dimensions the admin named over the ones known for the model' do
      connection.update!(config: connection.config.merge('embedding_size' => 512))

      expect(described_class.of(connection)).to include(size: 512)
    end

    it 'is nothing for a connection that names no model' do
      expect(described_class.of(create(:ai_provider_connection, provider: 'anthropic', config: { token: 'a' }))).to be_nil
    end

    it 'is nothing without a connection at all' do
      expect(described_class.of(nil)).to be_nil
    end
  end

  describe '.for_provider' do
    it 'describes values that are not stored yet' do
      expect(described_class.for_provider(provider: 'ollama', config: { url: 'http://localhost:11434', embedding_model: 'bge-m3' }))
        .to eq(model: 'bge-m3', size: AI::Provider::EMBEDDING_SIZES['bge-m3'])
    end

    # The save drops it too (AI::ProviderConnection#remove_unconfigurable_embedding_model), so
    # reading it would describe a configuration that is about to be discarded.
    it 'ignores an embedding model a provider serving a fixed one cannot store' do
      expect(described_class.for_provider(provider: 'zammad_ai', config: { token: 'a', embedding_model: 'text-embedding-3-small' }))
        .to include(model: AI::Provider::ZammadAI.embedding_model_fallback)
    end

    it 'is nothing for a provider that is none' do
      expect(described_class.for_provider(provider: 'nonsense', config: {})).to be_nil
    end
  end

  describe '.current' do
    it 'describes the connection serving semantic search' do
      expect(described_class.current).to eq(described_class.of(connection))
    end

    it 'is nothing while the AI provider is switched off' do
      Setting.set('ai_provider', false)

      expect(described_class.current).to be_nil
    end
  end

  describe '.changed?' do
    let(:openai) { described_class.of(connection) }

    it 'is a change when the model differs' do
      expect(described_class.changed?(openai, openai.merge(model: 'text-embedding-3-large'))).to be(true)
    end

    # Not because it changes the vectors - no provider is told what length to return - but because it
    # is what the index mapping is created with, which no reload can alter afterwards.
    it 'is a change when only the dimensions differ' do
      expect(described_class.changed?(openai, openai.merge(size: 512))).to be(true)
    end

    it 'is no change for the same model and dimensions' do
      expect(described_class.changed?(openai, openai.dup)).to be(false)
    end

    # There is nothing left to rebuild from, so the index is left standing rather than dropped.
    it 'is no change when nothing embeds afterwards' do
      expect(described_class.changed?(openai, nil)).to be(false)
    end
  end

  # The model is what identifies the vectors - the rule the embedding cache is keyed by - so moving
  # it elsewhere is no reason to embed the whole knowledge base again.
  it 'describes the same configuration when the same model moves to another provider' do
    ollama    = described_class.for_provider(provider: 'ollama', config: { url: 'http://localhost:11434', embedding_model: 'bge-m3' })
    zammad_ai = described_class.for_provider(provider: 'zammad_ai', config: { token: 'a' })

    expect(described_class.changed?(ollama, zammad_ai)).to be(false)
  end
end
