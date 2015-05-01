# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
# rubocop:disable ClassAndModuleChildren
class ApplicationModel::BackgroundJobSearchIndex
  def initialize(object, o_id)
    @object = object
    @o_id   = o_id
  end

  def perform
    Object.const_get(@object).find(@o_id).search_index_update_backend
  end
end
