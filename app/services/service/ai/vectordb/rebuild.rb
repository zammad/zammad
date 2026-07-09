# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  class Rebuild < Service::AI::VectorDB::Base
    attr_reader :worker

    def initialize(worker: 0)
      @worker = worker
    end

    def execute
      Service::AI::VectorDB::DropTable.execute
      Service::AI::VectorDB::CreateTable.execute
      # The index was just (re)created empty, so the reload can skip the per-record membership search.
      Service::AI::VectorDB::Reload.execute(worker:, fresh: true)
    end
  end
end
