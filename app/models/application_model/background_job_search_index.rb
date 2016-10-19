# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class ApplicationModel::BackgroundJobSearchIndex
  def initialize(object, o_id)
    @object = object
    @o_id   = o_id
  end

  def perform
    record = Object.const_get(@object).lookup(id: @o_id)
    if !record
      Rails.logger.info "Can't index #{@object}.find(#{@o_id}), no such record found"
      return
    end
    record.search_index_update_backend
  end
end
