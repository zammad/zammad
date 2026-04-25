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
      Service::AI::VectorDB::Reload.execute(worker:)
    end
  end
end
