# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class VectorIndexSyncJob < AIJob
  include HasActiveJobLock

  low_priority

  def perform
    return if !Service::CheckFeatureEnabled.execute(name: 'vectordb_enabled', exception: false)

    fresh = !Service::AI::VectorDB::Available.execute

    Service::AI::VectorDB::CreateTable.execute if fresh
    Service::AI::VectorDB::Reload.execute(fresh:)
  end
end
