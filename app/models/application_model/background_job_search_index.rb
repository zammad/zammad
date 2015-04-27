# perform background job
class ApplicationModel
  class BackgroundJobSearchIndex
    def initialize(object, o_id)
      @object = object
      @o_id   = o_id
    end

    def perform
      Object.const_get(@object).find(@o_id).search_index_update_backend
    end
  end
end
