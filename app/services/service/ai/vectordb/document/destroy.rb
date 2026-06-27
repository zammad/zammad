# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB::Document
  # Removes one document's chunk vectors. The embedding cache is left in place (cleaned only on
  # record deletion via `dependent: :destroy`), so a temporary unindex stays a cheap re-index.
  class Destroy < Service::AI::VectorDB::Base
    attr_reader :o_id, :object_name

    def initialize(object_id:, object_name:)
      @o_id        = object_id
      @object_name = object_name
    end

    def execute
      ai_vector_db.destroy(object_id: o_id, object_name:)
    end
  end
end
