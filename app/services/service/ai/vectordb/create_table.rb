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

      configured_embedding_size(provider.config[:embedding_size]) ||
        provider.class.known_embedding_default(:EMBEDDING_SIZES, embedding_model) ||
        raise(AI::VectorDB::MigrationError, __('The currently selected AI provider does not support embeddings.'))
    end

    # The dialog submits the dimension as a number, but the config is jsonb and keeps whatever an
    # API update wrote into it - down to a string ('1024'), which the index mapping cannot be built
    # from. Anything that is not a positive whole number is no dimension at all, so it falls through
    # to the provider's known default instead of reaching Elasticsearch.
    def configured_embedding_size(value)
      size = Integer(value.to_s, exception: false)

      size if size&.positive?
    end
  end
end
