# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Durable, content-addressed embedding cache: one AI::StoredResult row per indexed record holds a
# `{ digest => vector }` map. It lives in Postgres, so it survives an index rebuild, and is cleaned
# up with the record (`dependent: :destroy`) — no TTL.
class Service::AI::VectorDB::Embedding::Cache
  # Namespaces the cache rows in the shared ai_stored_results table (the StoredResult `identifier`).
  IDENTIFIER = 'vectordb_index'.freeze

  class << self
    # @return [Hash{String=>Array<Numeric>}] cached vectors keyed by #digest (empty if uncached)
    def fetch(object_name:, object_id:)
      row(object_name, object_id)&.content || {}
    end

    # Overwrites the whole map for the record (vanished chunks drop out); `version` records the
    # embedding model the vectors were produced with.
    def write(object_name:, object_id:, model:, vectors:)
      AI::StoredResult
        .find_or_initialize_by(identifier: IDENTIFIER, related_object_type: object_name, related_object_id: object_id)
        .tap { |record| record.update!(version: model.to_s, content: vectors) }
    end

    def destroy(object_name:, object_id:)
      AI::StoredResult.where(identifier: IDENTIFIER, related_object_type: object_name, related_object_id: object_id).delete_all
    end

    # Map key for a chunk. Includes the embedding model so a model change misses (and re-embeds)
    # rather than returning a vector of the wrong model/dimension.
    def digest(text, model:)
      Digest::SHA256.hexdigest("#{model}\n#{text}")
    end

    private

    def row(object_name, object_id)
      AI::StoredResult.find_by(identifier: IDENTIFIER, related_object_type: object_name, related_object_id: object_id)
    end
  end
end
