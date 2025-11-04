# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  class SimilaritySearch < Service::AI::VectorDB::Base
    attr_reader :text

    def initialize(text:)
      super()

      @text = text
    end

    def execute
      ai_vector_db.ping!

      # First we need to embed the text.
      embedding = AI::Provider.current.new.embed(input: text)

      # Then we need to search the vector database for the most similar items.
      ai_vector_db.knn(embedding:, k: 2)
    end
  end
end
