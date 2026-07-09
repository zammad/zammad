# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  class Reload < Service::AI::VectorDB::Base
    attr_reader :worker, :fresh

    # `fresh: true` is set by Rebuild, which reloads onto a just-created empty index — the per-record
    # membership search is then skipped (it would only ever come back empty).
    def initialize(worker: 0, fresh: false)
      @worker = worker
      @fresh  = fresh
    end

    def execute
      ai_vector_db.ping!

      Models.all.keys.select { |model| model.include?(HasVectorIndex) }.each do |model|
        model.vector_index_reload(worker:, fresh:)
      end
    end
  end
end
