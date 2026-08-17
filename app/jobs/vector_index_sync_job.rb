# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class VectorIndexSyncJob < AIJob
  include HasActiveJobLock

  low_priority

  def perform
    return if !Service::CheckFeatureEnabled.execute(name: 'vectordb_enabled', exception: false)

    # The rebuild job decides for itself between a cheap reload and a full rebuild: it compares what
    # is configured now against what the index was last built with (recorded in the hidden setting
    # vectordb_indexed_embedding_configuration). Unchanged since the feature was switched off - the
    # likely case - reads its vectors back out of Postgres and only reloads them into Elasticsearch;
    # changed in the meantime, it rebuilds from scratch instead of mixing two embedding spaces.
    VectorIndexRebuildJob.perform_later
  end
end
