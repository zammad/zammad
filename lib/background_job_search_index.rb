# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class BackgroundJobSearchIndex
  def initialize(object, o_id)
    @object = object
    @o_id   = o_id
  end

  def perform
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
