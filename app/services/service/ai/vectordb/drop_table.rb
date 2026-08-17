# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  class DropTable < Service::AI::VectorDB::Base
    def execute
      # Only that Elasticsearch is reachable and compatible - not the full ping!, whose index check
      # raises exactly where a drop has nothing to do. A rebuild starts here, so requiring an index
      # to exist would make the first build impossible (AI::VectorDB#drop skips a missing one itself).
      ai_vector_db.ping!(only_version: true)
      ai_vector_db.drop
    end
  end
end
