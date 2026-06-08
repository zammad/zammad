# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  class DropTable < Service::AI::VectorDB::Base
    def execute
      ai_vector_db.ping!
      ai_vector_db.drop
    end
  end
end
