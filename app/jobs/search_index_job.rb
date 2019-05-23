class SearchIndexJob < ApplicationJob

  retry_on StandardError, attempts: 20, wait: lambda { |executions|
    executions * 10.seconds
  }

  def perform(object, o_id)
    @object = object
    @o_id   = o_id

    record = @object.constantize.lookup(id: @o_id)
    return if !exists?(record)

    record.search_index_update_backend
  end

  private

  def exists?(record)
    return true if record

    Rails.logger.info "Can't index #{@object}.lookup(id: #{@o_id}), no such record found"
    false
  end
end
