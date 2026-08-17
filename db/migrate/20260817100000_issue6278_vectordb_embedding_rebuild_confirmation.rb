# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6278VectorDBEmbeddingRebuildConfirmation < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    serve_vectordb_enabled_to_frontend
    create_indexed_embedding_configuration
  end

  private

  def serve_vectordb_enabled_to_frontend
    setting = Setting.find_by(name: 'vectordb_enabled')
    return if setting.nil?

    # Whether semantic search is switched on decides what parts of the interface are worth showing at
    # all, so the frontend gets to know it - for authenticated sessions only, which is where anything
    # asks.
    setting.preferences[:authentication] = true
    setting.frontend                     = true

    # This changes how the setting is delivered, not what it holds - so its own validation, which
    # asks whether the value is backed by an embedding provider, has nothing to say about it. Left on,
    # it would abort the migration on an install that switched semantic search on and later dropped
    # the connection serving it: nothing turns `vectordb_enabled` off in that case
    # (see AI::ProviderConnection#disable_ai_provider_without_connections, which only clears
    # `ai_provider`), so the stored value would fail a check no save here is responsible for.
    setting.skip_validate = true
    setting.save!
  end

  def create_indexed_embedding_configuration
    return if Setting.exists?(name: 'vectordb_indexed_embedding_configuration')

    Setting.create!(
      title:       'Vector DB indexed embedding configuration',
      name:        'vectordb_indexed_embedding_configuration',
      area:        'VectorDB',
      description: 'Internal record of the embedding model and vector size the knowledge base index was last built with. Used to detect a stale index by comparison, without probing Elasticsearch.',
      options:     {},
      state:       {},
      frontend:    false,
    )

    return if !Setting.get('vectordb_enabled')

    # Every earlier enable rebuilt the index from scratch (VectorIndexSyncJob), so an install that
    # already has semantic search on is assumed to hold vectors matching what it is configured with
    # right now - there was no other way for it to get there.
    configuration = Service::AI::VectorDB::Embedding::Configuration.current
    return if configuration.nil?

    Setting.set('vectordb_indexed_embedding_configuration', configuration)
  end
end
