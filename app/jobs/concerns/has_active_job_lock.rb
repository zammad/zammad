# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module HasActiveJobLock
  class LockKeyNotGeneratable < StandardError; end

  # Sets default behaviour how to treat existing active job locks
  #
  # :dismiss - Simply do not enqueue the job if there's one enqueued.
  #            But still enqueue if same job is already running!
  #
  # :dismiss_running - Simply do not enqueue the job. Even if matching job is already running!
  #
  # :upsert_date - If there's already a job enqueued with the same lock key AND scheduled_at date,
  #                update the existing job's scheduled_at date.
  #                If matching job is already runnig, enqueues a new job!
  #
  EXISTING_ACTIVE_JOB_LOCK_BEHAVIOUR = :dismiss

  extend ActiveSupport::Concern

  included do
    before_enqueue do |job| # rubocop:disable Style/SymbolProc
      job.ensure_active_job_lock_for_enqueue!
    end

    around_perform do |job, block|
      # do not perform job if lock key cannot be generated anymore
      raise LockKeyNotGeneratable if job.safe_lock_key.nil?

      job.mark_active_job_lock_as_started

      block.call
    ensure
      job.release_active_job_lock!
    end
  end

  # Defines the lock key for the current job to prevent execution of jobs with the same key.
  # This is by default the name of the ActiveJob class.
  # If you're in the situation where you need to have a lock_key based on
  # the given arguments you can overwrite this method in your job and access
  # them via `arguments`. See ActiveJob::Core for more (e.g. queue).
  #
  # @example
  #  # default
  #  job = UniqueActiveJob.new
  #  job.lock_key
  #  # => "UniqueActiveJob"
  #
  # @example
  #  # with lock_key: "#{self.class.name}/#{arguments[0]}/#{arguments[1]}"
  #  job = SearchIndexJob.new('User', 42)
  #  job.lock_key
  #  # => "SearchIndexJob/User/42"
  #
  # return [String]
  def lock_key
    self.class.name
  end

  # Caches lock key for the duration of the job'
  # Silences errors thrown when generating lock key
  #
  # return [String]
  def safe_lock_key
    @safe_lock_key ||= lock_key
  rescue
    nil
  end

  def mark_active_job_lock_as_started
    release_active_job_lock_cache

    in_active_job_lock_transaction do
      # a perform_now job doesn't require any locking
      return if active_job_lock.blank?
      return if !active_job_lock.of?(self)

      # a perform_later job started to perform and will be marked as such
      active_job_lock.touch # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def ensure_active_job_lock_for_enqueue!
    release_active_job_lock_cache

    throw :abort if safe_lock_key.nil?

    in_active_job_lock_transaction do
      return if active_job_lock_for_enqueue!.present?

      ActiveJobLock.create!(
        lock_key:      safe_lock_key,
        active_job_id: job_id,
      )
    end
  end

  def release_active_job_lock!
    # nothing to release if lock key cannot be generated anymore
    return if safe_lock_key.nil?

    # only delete lock if the current job is the one holding the lock
    # perform_now jobs or perform_later jobs for which follow-up jobs were enqueued
    # don't need to remove any locks
    lock = ActiveJobLock.lock.find_by(lock_key: safe_lock_key, active_job_id: job_id)

    if !lock
      logger.debug { "Found no ActiveJobLock for #{self.class.name} (Job ID: #{job_id}) with key '#{safe_lock_key}'." }
      return
    end

    logger.debug { "Deleting ActiveJobLock for #{self.class.name} (Job ID: #{job_id}) with key '#{safe_lock_key}'." }
    lock.destroy!
  end

  private

  def in_active_job_lock_transaction(&)
    # re-use active DB transaction if present
    return yield if ActiveRecord::Base.connection.open_transactions.nonzero?

    # start own serializable DB transaction to prevent race conditions on DB level
    ActiveJobLock.transaction(isolation: :serializable, &)
  rescue ActiveRecord::SerializationFailure => e
    # PostgeSQL prevents locking on records that are already locked
    # for UPDATE in Serializable Isolation Level transactions,
    # but it's safe to retry as described in the docs:
    # https://www.postgresql.org/docs/10/transaction-iso.html
    e.message.include?('PG::TRSerializationFailure') ? retry : raise
  rescue ActiveRecord::Deadlocked => e
    # MySQL handles lock race condition differently and raises a Deadlock exception:
    # Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction
    e.message.include?('Mysql2::Error: Deadlock found when trying to get lock') ? retry : raise
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def active_job_lock_for_enqueue!
    return if active_job_lock.blank?

    case self.class::EXISTING_ACTIVE_JOB_LOCK_BEHAVIOUR
    when :dismiss
      throw :abort if active_job_lock.perform_pending? && active_job_lock.related_job.present?
    when :dismiss_running
      throw :abort if active_job_lock.related_job.present?
    when :upsert_date
      existing_active_job_lock! if active_job_lock.perform_pending?
    end

    active_job_lock.tap { |lock| lock.transfer_to(self) }
  end

  def active_job_lock
    @active_job_lock ||= ActiveJobLock.lock.find_by(lock_key: safe_lock_key)
  end

  def release_active_job_lock_cache
    @active_job_lock = nil
  end

  def existing_active_job_lock!
    throw :abort if scheduled_at.blank? # apply to postponed jobs only

    if active_job_lock && !active_job_lock.perform_pending?
      active_job_lock.transfer_to(self)
      return
    end

    delayed_job = Delayed::Job.find_by('handler LIKE ?', "%#{active_job_lock.active_job_id}%")

    if !delayed_job
      active_job_lock.transfer_to(self)
      return
    end

    delayed_job.update!(run_at: scheduled_at)

    throw :abort
  end
end
