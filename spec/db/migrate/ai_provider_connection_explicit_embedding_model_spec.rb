# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AIProviderConnectionExplicitEmbeddingModel, :aggregate_failures, type: :db_migration do
  # The connection relied on the former silent fallback: flagged for embeddings, but naming no
  # model. update_column, because the validation this migration exists for would reject it.
  def connection_without_embedding_model(provider, config)
    create(:ai_provider_connection, provider:, config: config.merge(embedding_model: 'to-be-removed'))
      .tap { |connection| connection.update_column(:config, config.stringify_keys) }
  end

  it 'performs no action for new systems', system_init_done: false do
    connection = connection_without_embedding_model('open_ai', { token: 'sk-123' })

    expect { migrate }.not_to raise_error

    expect(connection.reload.config).not_to have_key('embedding_model')
  end

  it 'backfills the model the fallback used to resolve to' do
    connection = connection_without_embedding_model('open_ai', { token: 'sk-123' })

    migrate

    expect(connection.reload.config)
      .to eq('token' => 'sk-123', 'embedding_model' => AI::Provider::OpenAI.recommended_embedding_model)
  end

  it 'backfills every provider with its own recommendation' do
    connection = connection_without_embedding_model('ollama', { url: 'http://localhost:11434' })

    migrate

    expect(connection.reload.config['embedding_model']).to eq(AI::Provider::Ollama.recommended_embedding_model)
  end

  it 'leaves a connection that already names its model alone' do
    connection = create(:ai_provider_connection, provider: 'open_ai',
                                                 config:   { token: 'sk-123', embedding_model: 'text-embedding-3-large' })

    migrate

    expect(connection.reload.config['embedding_model']).to eq('text-embedding-3-large')
  end

  it 'leaves a connection that does not serve embeddings alone' do
    connection = create(:ai_provider_connection, provider: 'anthropic', config: { token: 'sk-123' })

    migrate

    expect(connection.reload.config).not_to have_key('embedding_model')
  end

  # Zammad AI serves a fixed model, so such a connection needs no backfill and keeps serving.
  it 'leaves a provider whose model is not configurable serving embeddings', :aggregate_failures do
    connection = create(:ai_provider_connection, provider: 'zammad_ai', config: { token: 'sk-123' })

    migrate

    expect(connection.reload.default_embedding?).to be true
    expect(connection.config).not_to have_key('embedding_model')
  end

  # A custom endpoint serves whatever was deployed there, so there is nothing to backfill with. The
  # flag has to go, or the record stays one its own validation rejects - which would then take the
  # next save of any sibling connection down with it.
  context 'with a connection whose model cannot be named' do
    let(:connection) do
      connection_without_embedding_model('custom_open_ai', { url: 'https://example.com/v1', model: 'gpt-4o' })
        .tap { |conn| conn.update_column(:default_embedding, true) }
    end

    it 'stops it from serving embeddings instead of failing the migration', :aggregate_failures do
      connection

      expect { migrate }.not_to raise_error

      expect(connection.reload.default_embedding?).to be false
      expect(connection.config).not_to have_key('embedding_model')
    end

    it 'leaves the sibling maintenance saves working afterwards' do
      connection
      other = create(:ai_provider_connection, provider: 'open_ai', config: { token: 'a', embedding_model: 'text-embedding-3-small' })

      migrate

      expect { other.reload.update!(default_ocr: true) }.not_to raise_error
    end
  end

  # Only an API write ever put such a value there, and the upgrade of an installation carrying one
  # must not stop on it.
  context 'with a connection whose embedding metadata is unusable' do
    let(:connection) do
      connection_without_embedding_model('open_ai', { token: 'sk-123' })
        .tap { |conn| conn.update_column(:config, { 'token' => 'sk-123', 'embedding_input_limit' => -1 }) }
    end

    it 'leaves it alone instead of failing the migration', :aggregate_failures do
      connection

      expect { migrate }.not_to raise_error

      expect(connection.reload.config).not_to have_key('embedding_model')
    end

    it 'leaves the maintenance saves working afterwards', :aggregate_failures do
      connection
      other = create(:ai_provider_connection, provider: 'open_ai', config: { token: 'a', embedding_model: 'text-embedding-3-small' })

      migrate

      expect { other.reload.update!(default_ocr: true) }.not_to raise_error
      # The flag it cannot back with a model is dropped on its own next save, as for any legacy data.
      expect { connection.reload.update!(name: 'renamed') }.not_to raise_error
    end
  end
end
