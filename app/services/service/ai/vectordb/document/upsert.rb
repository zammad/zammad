# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB::Document
  # Indexes one document (entity) as content-addressed chunks (each chunk's id is a hash of its
  # text). Only chunks whose text is new get embedded — a batched provider round-trip; unchanged
  # chunks reuse their stored vector (skip-recalc) but are re-upserted so metadata (e.g.
  # group/category used for permission filtering) stays fresh. Chunks that vanished on the edit are
  # removed. Chunking + embedding are details of this service; the per-vector reads/writes are
  # AI::VectorDB primitives.
  class Upsert < Service::AI::VectorDB::Base
    attr_reader :object_name, :o_id, :content, :content_meta_headers, :strategy, :metadata

    def initialize(object_name:, object_id:, content:, content_meta_headers: [], strategy: :sentence, metadata: {})
      @object_name          = object_name
      @o_id                 = object_id
      @content              = content.to_s
      @content_meta_headers = content_meta_headers
      @strategy             = strategy
      @metadata             = metadata
    end

    def execute
      chunks  = chunk_content.uniq
      vectors = resolve_vectors(chunks) # chunk => vector

      upsert_chunks(chunks, vectors)
      cache_vectors(vectors)
      remove_stale(chunks)
    end

    private

    def chunk_content
      # develop base: default to the existing :sentence strategy for now (the :recursive strategy is
      # available too). The embedding model's input limit only caps the chunk size; the strategy
      # picks the actual size.
      Service::AI::VectorDB::Content::Chunks.execute(
        content:, content_meta_headers:, strategy:,
        model_max_tokens: embedding_provider&.embedding_input_limit
      )
    end

    # Deletes indexed chunks that are no longer part of the current content. Chunk ids are
    # content-addressed, so the stale set is the indexed ids minus the current ones.
    def remove_stale(chunks)
      current = chunks.map { |chunk| ai_vector_db.build_identifier(object_name:, object_id: o_id, content: chunk) }

      (ai_vector_db.document_ids(object_id: o_id, object_name:) - current).each do |id|
        ai_vector_db.delete(id:)
      end
    end

    def upsert_chunks(chunks, vectors)
      chunks.each do |chunk|
        ai_vector_db.upsert(object_id: o_id, object_name:, content: chunk, metadata:, embedding: vectors.fetch(chunk)) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    # Resolves a vector for every chunk: reuse the durable embedding cache where it has them (so a
    # full reindex — empty index — does not re-embed and a model change misses via the model-scoped
    # digest), then embed the remaining misses in one batched provider round-trip.
    def resolve_vectors(chunks)
      reused, misses = partition_cached(chunks, embedding_cache)
      return reused if misses.empty?

      reused.merge(misses.zip(Service::AI::VectorDB::Embedding.execute(input: misses)).to_h)
    end

    def partition_cached(chunks, cached)
      reused = {}
      misses = []
      chunks.each do |chunk|
        vector = cached[cache_digest(chunk)]
        vector ? (reused[chunk] = vector) : (misses << chunk)
      end
      [reused, misses]
    end

    # Overwrites the record's cache map with the current chunks' vectors, so vanished chunks drop
    # out. Survives a full reindex because it lives in Postgres, not the vector index.
    def cache_vectors(resolved)
      vectors = resolved.to_h { |chunk, vector| [cache_digest(chunk), vector] }
      Service::AI::VectorDB::Embedding::Cache.write(object_name:, object_id: o_id, model: embedding_model, vectors:)
    end

    def cache_digest(chunk)
      Service::AI::VectorDB::Embedding::Cache.digest(chunk, model: embedding_model)
    end

    def embedding_cache
      @embedding_cache ||= Service::AI::VectorDB::Embedding::Cache.fetch(object_name:, object_id: o_id)
    end

    def embedding_provider
      @embedding_provider ||= AI::Provider.current&.new
    end

    def embedding_model
      @embedding_model ||= embedding_provider&.options&.dig(:embedding_model)
    end
  end
end
