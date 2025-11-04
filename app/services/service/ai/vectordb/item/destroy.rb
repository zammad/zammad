# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB::Item
  class Destroy < Service::AI::VectorDB::Base
    attr_reader :o_id, :object_name

    def initialize(object_id:, object_name:)
      super()

      @o_id = object_id
      @object_name = object_name
    end

    def execute
      ai_vector_db.destroy(object_id: o_id, object_name:)
    end
  end
end
