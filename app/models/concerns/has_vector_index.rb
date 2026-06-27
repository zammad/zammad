# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module HasVectorIndex
  extend ActiveSupport::Concern

  included do
    # Transient flag a related model can set (e.g. an associated content record on its own change)
    # to force the full re-embed path, since such a change is invisible in this record's own
    # previous_changes. Reset per instance, never persisted.
    attr_accessor :vector_index_content_dirty

    after_commit  :vector_index_update_later, if: :persisted?
    after_destroy :vector_index_destroy
  end

  def vector_index_update_later
    return true if !Service::AI::VectorDB::Available.execute(ping: false)

    return true if previous_changes.blank?

    if respond_to?(:vector_indexing_for_record?) && !vector_indexing_for_record?
      vector_index_destroy
      return true
    end

    if !vector_index_content_changed?
      VectorIndexJob.perform_later(self.class.to_s, id, :metadata)
      return true
    end

    VectorIndexJob.perform_later(self.class.to_s, id)

    true
  end

  def vector_index_content_changed?
    true
  end

  def vector_index_update_metadata
    data = vector_index_data

    updated = Service::AI::VectorDB::Document::UpdateMetadata.execute(
      object_name: data[:object_name] || self.class.to_s,
      object_id:   data[:object_id] || id,
      metadata:    data[:metadata] || {},
    )

    # Nothing was indexed for this record (e.g. it just came back into scope after its vectors were
    # removed, or the index was rebuilt) → there is nothing to patch, so do a full embed instead.
    vector_index_update if updated.zero?
  end

  def vector_index_update
    data = vector_index_data

    Service::AI::VectorDB::Document::Upsert.execute(
      object_name:          data[:object_name] || self.class.to_s,
      object_id:            data[:object_id] || id,
      content:              data[:content],
      content_meta_headers: data[:content_meta_headers] || [],
      strategy:             vector_index_chunking_strategy,
      metadata:             data[:metadata] || {},
    )
  end

  def vector_index_destroy
    return true if !Service::AI::VectorDB::Available.execute(ping: false)

    Service::AI::VectorDB::Document::Destroy.execute(object_name: self.class.to_s, object_id: id)
  end

  class_methods do
    def vector_index_reload(silent: false, worker: 0)
      return if !Service::AI::VectorDB::Available.execute

      scope = if respond_to?(:vector_index_scope)
                vector_index_scope
              else
                all
              end

      scope.in_batches do |batch|
        Parallel.map(batch, { in_processes: worker }) do |record|
          begin
            record.vector_index_update
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
