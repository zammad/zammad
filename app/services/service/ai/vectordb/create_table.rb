# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  class CreateTable < Service::AI::VectorDB::Base
    def execute
      ai_vector_db.ping!(only_version: true)
      ai_vector_db.migrate(dimensions: embedding_size)
    end

    private

    def embedding_size
      provider        = AI::Provider.current
      provider_config = provider.new.config

      embedding_model = provider_config['embedding_model'] || provider::DEFAULT_OPTIONS[:embedding_model]

      provider_config['embedding_size'].presence ||
        provider::EMBEDDING_SIZES[embedding_model] ||
        raise(AI::VectorDB::MigrationError, __('The currently selected AI provider does not support embeddings.'))
    end
  end
end
