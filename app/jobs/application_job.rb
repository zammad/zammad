# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ApplicationJob < ActiveJob::Base
  include ApplicationJob::HasDelayedJobMonitoringCompatibilty
  include ApplicationJob::HasQueuingPriority

  discard_on HasActiveJobLock::LockKeyNotGeneratable

  queue_as :default

  # See config/initializers/delayed_jobs_timeout_per_job.rb for details.
  def self.max_run_time
    4.hours
  end

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # This method is used to find the Delayed::Job record representing the ActiveJob with the given active_job_id.
  #
  # @param active_job_id [String] the ActiveJob job_id to look up
  # @return [Delayed::Job, Hash, nil] the related Delayed::Job record (for DelayedJobAdapter), the enqueued job hash (for TestAdapter), or nil if not found
  def self.job_by_active_job_id(active_job_id)
    case ActiveJob::Base.queue_adapter
    when ActiveJob::QueueAdapters::DelayedJobAdapter
      delayed_job_by_active_job_id(active_job_id)
    when ActiveJob::QueueAdapters::TestAdapter
      test_adapter_job_by_active_job_id(active_job_id)
    end
  end

  def self.test_adapter_job_by_active_job_id(active_job_id)
    ActiveJob::Base.queue_adapter.enqueued_jobs.find { it['job_id'] == active_job_id }
  end
  private_class_method :test_adapter_job_by_active_job_id

  def self.delayed_job_by_active_job_id(active_job_id)
    # This is a fallback for running old migrations before this column was added.
    # Otherwise some old migrations fail to ad background jobs.
    if Delayed::Job.column_names.exclude?('active_job_id')
      return Delayed::Job
        .where(
          'handler LIKE :no_quotes OR handler LIKE :with_quotes',
          no_quotes:   "%job_id: #{active_job_id}%",
          with_quotes: "%job_id: '#{active_job_id}'%"
        ).first
    end

    Delayed::Job.find_by(active_job_id:)
  end
  private_class_method :delayed_job_by_active_job_id
end
