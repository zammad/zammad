# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The reconciler for the vector index: brings it in line with the embedding configuration currently
# in effect, whichever way it drifted out of sync - a config change, a switch flipped while it was
# off, or the index simply never having been built. Enqueued by Service::AI::VectorDB::Reconcile
# whenever it finds a mismatch. A configuration that keeps moving mid-run stops the run between
# documents, and the job restarts itself with the new one (see #release_active_job_lock!).
class VectorIndexRebuildJob < AIJob
  include HasActiveJobLock

  low_priority

  # One rebuild at a time, even while one is running: the ai queue runs several worker threads
  # (BackgroundServices::Service::ProcessDelayedAIJobs), so an enqueue merely queued behind a
  # running rebuild would in fact start alongside it - and drop the index out from under it.
  # What a dismissed enqueue asked for is never lost: the job compares state once more after its
  # lock is released and restarts itself (see #release_active_job_lock!).
  EXISTING_ACTIVE_JOB_LOCK_BEHAVIOUR = :dismiss_running

  # How often a run is retried before it is left to fail.
  ATTEMPTS = 10

  # One curve for every way a rebuild can fail: 30 seconds, doubling to a half hour cap, which spends
  # the whole budget over roughly two hours. Short at the start, where a restarting Elasticsearch or a
  # blipping endpoint is the likely cause, and long by the end, where a provider quota that refills by
  # the hour is - a rebuild embeds the whole knowledge base in one burst, which is what runs into one.
  #
  # No special case per kind of failure, because the providers signal a rate limit in whatever way
  # they please: a 429, a 503, or an error message in an otherwise fine response.
  WAIT = ->(executions) { [30 * (2**(executions - 1)), 30.minutes.to_i].min.seconds }

  # Deliberately without arguments: everything a run needs is read here, at whichever attempt
  # actually gets to run it - so an enqueue dismissed against the lock loses nothing.
  def perform
    # Whatever this run ends as - done, obsolete, or nothing to do - the state is compared once more
    # after the lock is gone (see #release_active_job_lock!). Only a failure opts out: its retry
    # continues the run, and a restart on top of it would rebuild alongside it.
    @reconcile_after_release = true

    # Re-read rather than trusted from enqueue time: the job is coalesced and delayed, so the vector
    # database may have been switched off since whatever asked for this.
    return if !Service::CheckFeatureEnabled.execute(name: 'vectordb_enabled', exception: false)

    # Captured once, at the start of this attempt: everything below judges and then records against
    # this same value, not against whatever the connection reads as by the time the rebuild finishes.
    configuration = Service::AI::VectorDB::Embedding::Configuration.current
    # Nothing to build with - the index is left standing rather than dropped for nothing to refill it.
    return if configuration.nil?

    indexed = Service::AI::VectorDB::Embedding::Configuration.indexed
    stale   = indexed.nil? || Service::AI::VectorDB::Embedding::Configuration.changed?(indexed, configuration)

    # Checked between documents: a configuration that changed under this run makes everything still
    # ahead of it money spent on an index the restart drops - so the run stops instead, and the
    # restart takes over with the new configuration.
    abort_when = lambda do
      Service::AI::VectorDB::Embedding::Configuration.changed?(configuration, Service::AI::VectorDB::Embedding::Configuration.current)
    end

    if !stale && Service::AI::VectorDB::Available.execute
      # The configuration the index was built with still holds - only a plain reload into the index
      # that is already there, for documents that may have changed while the feature was off. Nothing
      # is dropped, so the record stays true whatever happens to this run.
      Service::AI::VectorDB::Reload.execute(abort_when:)
    else
      purge_stale_caches(indexed) if stale

      # Before the drop, because the drop is what makes the old record a lie - and from here nothing
      # can be said about what the index holds until the rebuild below has finished. Every unhappy
      # ending then leaves "nothing built": an abort, a failure, the retry budget running out, or
      # the worker being killed, which no rescue here would catch. The next reconcile finds a
      # mismatch and rebuilds, and a change back to the previously indexed configuration - the
      # natural reaction to a failed rebuild - is no longer mistaken for "nothing to do".
      Service::AI::VectorDB::Embedding::Configuration.record_indexed(nil)

      Service::AI::VectorDB::Rebuild.execute(abort_when:)
    end

    # The value captured at the start of this attempt, not a fresh read: reading again here would
    # mark a configuration that changed mid-run as clean, and the after-release comparison would
    # then find nothing to repair.
    Service::AI::VectorDB::Embedding::Configuration.record_indexed(configuration)
  rescue Service::AI::VectorDB::Reload::Aborted
    # Obsolete, not broken: no retry, no attempt spent - the restart does the rebuilding.
    nil
  rescue => e
    @reconcile_after_release = false

    retry_or_give_up(e)
  end

  # Two jobs in one: besides releasing (or, for a retry, keeping) the lock, this is where the job
  # restarts itself. After `super` the lock is gone, which is what makes the handover loss-free: a
  # configuration change up to this point is found by this comparison, and one after it enqueues
  # freely - there is no moment left in which a change could be dismissed against a lock nobody
  # answers for anymore. Usually the comparison simply finds the state this run just recorded and
  # does nothing.
  def release_active_job_lock!
    # The retry keeps this job's id (retry_job enqueues a dup), so it takes the lock over rather
    # than queueing behind it - releasing here would delete the lock the pending retry is holding,
    # and a restart on top would rebuild alongside it.
    return if @retry_enqueued

    super

    return if !@reconcile_after_release

    Service::AI::VectorDB::Reconcile.execute
  end

  private

  # The vectors of a configuration the index no longer holds. The ticket ones
  # (Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache) go for any stale index, known
  # or unknown - their key is not model-scoped, so keeping them would have the search comparing two
  # embedding spaces. The knowledge base ones (Service::AI::VectorDB::Embedding::Cache) only where a
  # known previous configuration marks them worthless: their digests are model-scoped, so leftovers
  # of an unknown one are unreadable rather than wrong, and throwing them away on a guess would
  # charge the whole knowledge base again where the guess was too careful.
  #
  # Skipped on a retry: what the attempt before it cached is what makes the next one cheap, and
  # nothing changed the configuration again in between - a further change restarts the job anyway.
  # Skipped as well when the index is merely missing but the configuration is unchanged: the caches
  # already hold vectors of the configuration the rebuild is about to embed with again.
  def purge_stale_caches(indexed)
    return if executions > 1

    Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache.purge

    return if indexed.nil?

    Service::AI::VectorDB::Embedding::Cache.purge
  end

  # Giving up means failing: the failed background job is what MonitoringHelper::HealthChecker::DelayedJob
  # reports, and the provider connection already carries the reason as its status
  # (AI::ProviderConnection#record_call). Swallowing it here would leave a stale index and nothing
  # anywhere saying so.
  def retry_or_give_up(error)
    raise error if executions >= ATTEMPTS

    wait = WAIT.call(executions)

    Rails.logger.info { "Retrying the vector index rebuild in #{wait.inspect} after: #{error.message}" }

    # The lock goes before the retry is enqueued rather than when this run returns. :dismiss_running
    # throws away any enqueue that finds a lock whose job still exists, and while this job performs,
    # its own row is exactly such a job - so the retry would be dismissed and the failure swallowed.
    # Released here (the guard above only takes effect once @retry_enqueued is set), the retry's own
    # enqueue creates the lock again under the same job id, which the guard then leaves alone.
    release_active_job_lock!

    @retry_enqueued = true

    return if retry_job(wait:, error:)

    # Something dismissed the retry all the same - most likely another rebuild enqueued in the
    # microseconds without a lock. Better to fail than to leave a half-built index with nothing
    # anywhere saying so: whoever took the lock rebuilds from state, and this run is on record as
    # failed either way.
    @retry_enqueued = false

    raise error
  end
end
