class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # We (currently) rely on Delayed::Job#attempts to check for stuck backends
  # e.g. in the MonitoringController.
  # This is a workaround to sync ActiveJob#executions to Delayed::Job#attempts
  # until we resolve this dependency.
  around_enqueue do |job, block|
    block.call.tap do |delayed_job|
      delayed_job.update!(attempts: job.executions)
    end
  end
end
