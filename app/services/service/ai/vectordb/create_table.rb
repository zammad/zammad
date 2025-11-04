# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  class CreateTable < Service::AI::VectorDB::Base
    def execute
      ai_vector_db.ping!(only_version: true)
      ai_vector_db.migrate(dimensions: embedding_size)
    end

    private

    def embedding_size
      provider = AI::Provider.current

      embedding_sizes = provider.const_get(:EMBEDDING_SIZES)

      if embedding_sizes.blank?
        raise AI::VectorDB::MigrationError, __('The currently selected AI provider does not support embeddings.')
      end

      embedding_sizes.fetch(provider.const_get(:DEFAULT_OPTIONS)[:embedding_model])
    end
  end
end
