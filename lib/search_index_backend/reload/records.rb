# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The records of one model in a reload of the search index: hands out their ids in slices, newest first, and
# indexes a slice.
class SearchIndexBackend::Reload::Records
  BATCH_SIZE  = 200
  BULK_SIZE   = 100
  TOLERANCE   = 10
  RETRY_DELAY = 15.seconds

  attr_reader :model, :worker, :total, :count, :handed_out, :last_id, :failed_count

  def initialize(model, worker: 0)
    @model        = model
    @worker       = worker
    @total        = model.uncached { model.count }
    @count        = 0
    @handed_out   = 0
    @failed_count = 0
    @exhausted    = false
  end

  def exhausted?
    @exhausted
  end

  def finished?
    exhausted? && count == handed_out
  end

  # Sorted by id and not by time of creation, so no model needs an index on that time.
  def next_slices
    return [] if exhausted?

    scope = model.reorder(id: :desc).limit(BATCH_SIZE)
    scope = scope.where(id: ...last_id) if last_id

    # A caller with an active query cache gets the current records with every reload.
    ids = model.uncached { scope.ids }

    @exhausted  = ids.size < BATCH_SIZE
    @last_id    = ids.last if ids.any?
    @handed_out = handed_out + ids.size

    ids.each_slice(bulk_size(ids.size)).to_a
  end

  def index(ids)
    # Every worker counts the failures of its slice, as each of them counted its part of a batch before.
    @failed_count = 0 if worker.positive?

    records = model.uncached { model.where(id: ids).reorder(id: :desc).to_a }
    failed  = add_bulk(records)
    return if failed.empty?

    begin
      add_single(failed)
    ensure
      remove_destroyed(failed)
    end
  ensure
    # A worker lives for many slices and would keep the cached lookups of all their records.
    ActiveSupport::CurrentAttributes.clear_all if worker.positive?
  end

  def done(ids)
    @count = count + ids.size
  end

  private

  # Every worker gets a part of a batch.
  def bulk_size(size)
    (size.to_f / [worker, 1].max).ceil.clamp(1, BULK_SIZE)
  end

  # Returns the records which are not in the search index afterwards.
  def add_bulk(records)
    bulk   = SearchIndexBackend::Bulk.new(model.to_s)
    failed = []

    ApplicationModel::CanLookupSearchIndexAttributes::RequestCache.refresh

    records.each do |record|
      next if record.ignore_search_indexing?(:destroy)

      attributes = record.search_index_attribute_lookup
      bulk.add(attributes) if attributes
    rescue
      failed << record.id
    end

    bulk.flush
    failed.concat(bulk.failed_ids)

    destroyed = remove_destroyed(records)

    records.select { |record| failed.include?(record.id) && destroyed.exclude?(record.id) }
  end

  # The single request reports why a record failed, and indexes the ones a failed bulk request took down with it.
  def add_single(records)
    records.each do |record|
      record.search_index_update_backend
    rescue => e
      Rails.logger.error "Unable to send #{record.class}.find(#{record.id}).search_index_update_backend backend: #{e.inspect}"
      @failed_count = failed_count + 1
      sleep RETRY_DELAY
      raise "Unable to send #{record.class}.find(#{record.id}).search_index_update_backend backend: #{e.inspect}" if failed_count == TOLERANCE
    end
  end

  # The document of a record which was destroyed while it waited to be sent is written after its removal.
  def remove_destroyed(records)
    ids = records.map(&:id)

    (ids - model.uncached { model.unscoped.where(id: ids).ids }).each do |id|
      SearchIndexBackend.remove(model.to_s, id)
    end
  end
end
