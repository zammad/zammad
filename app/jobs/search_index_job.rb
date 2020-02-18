class SearchIndexJob < ApplicationJob
  include HasActiveJobLock

  retry_on StandardError, attempts: 20, wait: lambda { |executions|
    executions * 10.seconds
  }

  def lock_key
    # "SearchIndexJob/User/42/true"
    "#{self.class.name}/#{arguments[0]}/#{arguments[1]}/#{arguments[2]}"
  end

  def perform(object, o_id, update_associations = true)
    @object = object
    @o_id   = o_id

    record = @object.constantize.lookup(id: @o_id)
    return if !exists?(record)

    record.search_index_update_backend

    return if !update_associations

    record.search_index_update_associations_delta
    record.search_index_update_associations_full
  end

  private

  def exists?(record)
    return true if record

    Rails.logger.info "Can't index #{@object}.lookup(id: #{@o_id}), no such record found"
    false
  end
end
