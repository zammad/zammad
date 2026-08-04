# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  class SimilaritySearch < Service::AI::VectorDB::Base
    attr_reader :text, :embedding, :k, :filter

    def initialize(text: nil, embedding: nil, k: 2, filter: {}) # rubocop:disable Naming/MethodParameterName
      @text      = text
      @embedding = embedding
      @k         = k
      @filter    = filter
    end

    def execute
      ai_vector_db.ping!

      # Search the vector database for the most similar items, using the given embedding or embedding
      # the text on the fly. The filter restricts candidates to documents the caller may see.
      ai_vector_db.knn(embedding: query_embedding, k:, filter:)
    end

    private

    def query_embedding
      embedding || Service::AI::VectorDB::Embedding.execute(input: text)
    end
  end
end
