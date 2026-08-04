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

      embedding_model = provider.options[:embedding_model] || provider.class::DEFAULT_OPTIONS[:embedding_model]

      provider.config[:embedding_size].presence ||
        provider.class::EMBEDDING_SIZES[embedding_model] ||
        raise(AI::VectorDB::MigrationError, __('The currently selected AI provider does not support embeddings.'))
    end
  end
end
