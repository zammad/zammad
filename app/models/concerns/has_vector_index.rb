# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module HasVectorIndex
  extend ActiveSupport::Concern

  included do
    after_commit  :vector_index_update_later, if: :persisted?
    after_destroy :vector_index_destroy
  end

  # Enqueue a reindex when this record changed (its own change, or a related record touched it).
  # The reindex is a single idempotent "sync this document's chunks" operation, so being triggered
  # more than once for the same record is harmless: the job lock coalesces duplicates and each run
  # reads the current state.
  def vector_index_update_later
    return true if !Service::AI::VectorDB::Available.execute(ping: false)

    # A related record can touch this one for reasons that don't affect its vector document (a tag,
    # an attachment, an internal note, …). That touch still refreshes the search index via
    # HasSearchIndexBackend, but the vector reindex is skipped unless something feeding the document
    # actually changed. Models opt in by defining #vector_index_relevant_change?; the check may only
    # err towards reindexing (an extra run is a cheap no-op — a wrongly skipped one goes stale).
    # It must not lean on this record's own previous_changes being present — a touch_later touch
    # (Answer#touch_translations) leaves them empty. Models without the check reindex on any change
    # of their own.
    relevant = respond_to?(:vector_index_relevant_change?) ? vector_index_relevant_change? : previous_changes.present?
    return true if !relevant

    if respond_to?(:vector_indexing_for_record?) && !vector_indexing_for_record?
      vector_index_destroy
      return true
    end

    VectorIndexJob.perform_later(self.class.to_s, id)
    true
  end

  # Re-chunk, (re-)embed and upsert the record's content, removing chunks that vanished. Embedding
  # is skipped for unchanged chunks via the durable cache, so a metadata-only change does not pay
  # for re-embedding.
  # `fresh: true` (rebuild path) reindexes onto a just-created empty index, so the membership search
  # is skipped and the full path runs directly.
  def vector_index_update(fresh: false)
    # The record may have become non-indexable (per `vector_indexing_for_record?`) since the job was
    # enqueued; remove it instead of re-upserting a now-stale document.
    return vector_index_destroy if respond_to?(:vector_indexing_for_record?) && !vector_indexing_for_record?

    data = vector_index_data

    Service::AI::VectorDB::Document::Upsert.execute(
      object_name:           data[:object_name] || self.class.to_s,
      object_id:             data[:object_id] || id,
      content:               data[:content],
      content_meta_headers:  data[:content_meta_headers] || [],
      strategy:              vector_index_chunking_strategy,
      metadata:              data[:metadata] || {},
      skip_membership_check: fresh,
    )
  end

  def vector_index_destroy
    return true if !Service::AI::VectorDB::Available.execute(ping: false)

    Service::AI::VectorDB::Document::Destroy.execute(object_name: self.class.to_s, object_id: id)
  end

  class_methods do
    def vector_index_reload(silent: false, worker: 0, fresh: false)
      return if !Service::AI::VectorDB::Available.execute

      scope = if respond_to?(:vector_index_scope)
                vector_index_scope
              else
                all
              end

      scope.in_batches do |batch|
        Parallel.map(batch, { in_processes: worker }) do |record|
          begin
            record.vector_index_update(fresh:)
          rescue => e
            raise "Unable to update vector index for #{record.class}.find(#{record.id}): #{e.inspect}"
          end
        end
      end
    end
  end

  private

  def vector_index_data
    raise 'not implemented'
  end

  def vector_index_chunking_strategy
    :sentence
  end
end
