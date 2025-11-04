# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB::Item
  class Create < Service::AI::VectorDB::Base
    attr_reader :o_id, :object_name, :content, :metadata

    def initialize(object_id:, object_name:, content:, metadata: {})
      super()

      @o_id = object_id
      @object_name = object_name
      @content = content
      @metadata = metadata
    end

    def execute
      embedding = AI::Provider.current.new.embed(input: content)

      ai_vector_db.create(object_id: o_id, object_name:, content:, metadata:, embedding:)
    end
  end
end
