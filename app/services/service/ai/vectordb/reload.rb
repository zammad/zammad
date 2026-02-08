# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  class Reload < Service::AI::VectorDB::Base
    attr_reader :worker

    def initialize(worker: 0)
      super()

      @worker = worker
    end

    def execute
      ai_vector_db.ping!

      Models.all.keys.select { |model| model.include?(HasVectorIndex) }.each do |model|
        model.vector_index_reload(worker:)
      end
    end
  end
end
