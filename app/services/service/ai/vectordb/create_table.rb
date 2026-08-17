# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  class CreateTable < Service::AI::VectorDB::Base
    def execute
      ai_vector_db.ping!(only_version: true)
      ai_vector_db.migrate(dimensions: embedding_size)
    end

    private

    def embedding_size
      provider = AI::ProviderConnection.for_embeddings&.provider_instance
      raise(AI::VectorDB::MigrationError, __('The system currently has no selected AI provider for embeddings.')) if provider.nil?

      # The model the admin picked, or the fixed one of a provider that has no configurable model
      # (Zammad AI) - but never one resolved from the adapter's request time defaults.
      embedding_model = provider.embedding_model
      raise(AI::VectorDB::MigrationError, __('Missing embedding model in the provider configuration')) if embedding_model.blank?

      provider.embedding_size ||
        raise(AI::VectorDB::MigrationError, __('The currently selected AI provider does not support embeddings.'))
    end
  end
end
