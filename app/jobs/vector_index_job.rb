# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class VectorIndexJob < ApplicationJob
  include HasActiveJobLock

  low_priority

  retry_on StandardError, attempts: 20, wait: lambda { |executions|
    executions * 10.seconds
  }

  def lock_key
    # "VectorIndexJob/KnowledgeBase::Answer::Translation/42" — one key per record, so concurrent
    # triggers for the same record coalesce into a single reindex.
    "#{self.class.name}/#{arguments[0]}/#{arguments[1]}"
  end

  # `_mode` is ignored — kept so jobs enqueued before the single-mode change (which passed a mode
  # argument) still deserialize and run after deploy.
  def perform(object, o_id, _mode = nil)
    @object = object
    @o_id   = o_id

    record = @object.constantize.find_by(id: @o_id)
    return if !exists?(record)

    record.vector_index_update
  end

  private

  def exists?(record)
    return true if record

    Rails.logger.info "Can't update vector index for #{@object}.find_by(id: #{@o_id}), no such record found"
    false
  end
end
