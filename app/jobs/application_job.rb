# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ApplicationJob < ActiveJob::Base
  include ApplicationJob::HasDelayedJobMonitoringCompatibilty
  include ApplicationJob::HasQueuingPriority
  include ApplicationJob::HasCustomLogging

  discard_on HasActiveJobLock::LockKeyNotGeneratable

  ActiveJob::LogSubscriber.detach_from :active_job

  # See config/initializers/delayed_jobs_timeout_per_job.rb for details.
  def self.max_run_time
    4.hours
  end

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
