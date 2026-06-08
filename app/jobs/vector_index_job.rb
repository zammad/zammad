# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class VectorIndexJob < ApplicationJob
  include HasActiveJobLock

  low_priority

  retry_on StandardError, attempts: 20, wait: lambda { |executions|
    executions * 10.seconds
  }

  def lock_key
    # "VectorIndexJob/KnowledgeBase::Answer/42"
    "#{self.class.name}/#{arguments[0]}/#{arguments[1]}"
  end

  def perform(object, o_id)
    @object = object
    @o_id   = o_id

    record = @object.constantize.find_by(id: @o_id)
    return if !exists?(record)

    update_vector_index(record)
  end

  def update_vector_index(record)
    record.vector_index_update
  end

  private

  def exists?(record)
    return true if record

    Rails.logger.info "Can't update vector index for #{@object}.find_by(id: #{@o_id}), no such record found"
    false
  end
end
