# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  class CreateTable < Service::AI::VectorDB::Base
    attr_reader :feature_identifier

    # @param feature_identifier [String, Symbol, NilClass] the calling feature's identifier, so
    #   the embedding provider is resolved via that feature's routing (see
    #   AI::ProviderConnection.for_embeddings).
    def initialize(feature_identifier: nil)
      @feature_identifier = feature_identifier
    end

    def execute
      ai_vector_db.ping!(only_version: true)
      ai_vector_db.migrate(dimensions: embedding_size)
    end

    private

    def embedding_size
      provider = AI::ProviderConnection.for_embeddings(feature_identifier)&.provider_instance
      raise(AI::VectorDB::MigrationError, __('The currently selected AI provider does not support embeddings.')) if provider.nil?

      embedding_model = provider.options[:embedding_model] || provider.class::DEFAULT_OPTIONS[:embedding_model]

      provider.config[:embedding_size].presence ||
        provider.class::EMBEDDING_SIZES[embedding_model] ||
        raise(AI::VectorDB::MigrationError, __('The currently selected AI provider does not support embeddings.'))
    end
  end
end
