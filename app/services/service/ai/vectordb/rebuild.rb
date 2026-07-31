# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  class Rebuild < Service::AI::VectorDB::Base
    attr_reader :worker, :feature_identifier

    # @param feature_identifier [String, Symbol, NilClass] the calling feature's identifier, so
    #   the embedding provider used to size the new table is resolved via that feature's routing
    #   (see AI::ProviderConnection.for_embeddings).
    def initialize(worker: 0, feature_identifier: nil)
      @worker             = worker
      @feature_identifier = feature_identifier
    end

    def execute
      Service::AI::VectorDB::DropTable.execute
      Service::AI::VectorDB::CreateTable.execute(feature_identifier:)
      # The index was just (re)created empty, so the reload can skip the per-record membership search.
      Service::AI::VectorDB::Reload.execute(worker:, fresh: true)
    end
  end
end
