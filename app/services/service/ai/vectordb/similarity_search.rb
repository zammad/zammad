# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  class SimilaritySearch < Service::AI::VectorDB::Base
    attr_reader :text, :embedding, :k, :filter, :feature_identifier

    # @param feature_identifier [String, Symbol, NilClass] the calling feature's identifier, used
    #   to resolve the embedding provider (see AI::ProviderConnection.for_embeddings) when `text`
    #   is embedded on the fly; irrelevant when `embedding` is given directly.
    def initialize(text: nil, embedding: nil, k: 2, filter: {}, feature_identifier: nil) # rubocop:disable Naming/MethodParameterName
      @text               = text
      @embedding          = embedding
      @k                  = k
      @filter             = filter
      @feature_identifier = feature_identifier
    end

    def execute
      ai_vector_db.ping!

      # Search the vector database for the most similar items, using the given embedding or embedding
      # the text on the fly. The filter restricts candidates to documents the caller may see.
      ai_vector_db.knn(embedding: query_embedding, k:, filter:)
    end

    private

    def query_embedding
      embedding || Service::AI::VectorDB::Embedding.execute(input: text, feature_identifier:)
    end
  end
end
