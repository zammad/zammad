class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # We (currently) rely on Delayed::Job#attempts to check for stuck backends
  # e.g. in the MonitoringController.
  # This is a workaround to sync ActiveJob#executions to Delayed::Job#attempts
  # until we resolve this dependency.
  after_enqueue do |job|
    # update the column right away without loading Delayed::Job record
    # see: https://stackoverflow.com/a/34264580
    Delayed::Job.where(id: job.provider_job_id).update_all(attempts: job.executions) # rubocop:disable Rails/SkipsModelValidations
  end
end
