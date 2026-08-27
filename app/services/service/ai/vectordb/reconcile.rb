# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  # Whether what the index holds still matches what is configured, checked by comparing state rather
  # than by reacting to whatever event may have changed it - a trigger missed anywhere (an outage, a
  # setting flipped from the console, a change made while the feature was off) is repaired the next
  # time anything calls this, rather than staying stale until the next lucky trigger.
  class Reconcile < Service::Base
    def execute
      return if !Service::CheckFeatureEnabled.execute(name: 'vectordb_enabled', exception: false)

      desired = Service::AI::VectorDB::Embedding::Configuration.current
      # Nothing serves embeddings (also true with the AI provider off, which for_embeddings honors) -
      # the index is left standing rather than judged against a configuration that does not exist.
      return if desired.nil?

      return if desired == Service::AI::VectorDB::Embedding::Configuration.indexed

      VectorIndexRebuildJob.perform_later

      # The active-job lock may coalesce this enqueue into a rebuild that is already pending or
      # running. Either way, background reconciliation is in progress for the desired state.
      true
    end
  end
end
