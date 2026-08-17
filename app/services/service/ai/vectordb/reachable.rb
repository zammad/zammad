# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  # Whether Elasticsearch can be reached and speaks a version the vector database supports - which is
  # what *building* the index needs. Deliberately not Available: that one also asks for the index to
  # exist, which it does not before the first build, and which no amount of configuration can fix.
  #
  # Asked of Elasticsearch alone, without the AI provider gate Service::AI::VectorDB::Base applies:
  # whether a provider is configured is a different question with its own, more precise answer.
  class Reachable < Service::Base
    def execute
      AI::VectorDB.new.ping?(only_version: true)
    end
  end
end
