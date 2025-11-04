# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices::Service::ProcessScheduledJobs::JobExecutor
  include BackgroundServices::Concerns::HasInterruptibleSleep

  TRY_COUNT_MAX = 10

  attr_reader :job, :try_count, :try_run_time, :started_at

  def self.run(job)
    return if BackgroundServices.shutdown_requested

    klass = job.runs_as_persistent_loop? ? Continuous : OneTime
    klass.new(job).run
  end

  protected

  def initialize(job)
    @job            = job
    @try_count      = 0
    @try_run_time   = Time.current
  end

  def execute
    mark_as_started
    eval_job_method

  # Check for connection errors and initiate a process shutdown in this case,
  #   so that the process manager can restart it.
  rescue ActiveRecord::AdapterError => e
    log_execution_error(e)
    raise e

  # Catch all other StandardErrors to be able to retry the job execution.
  rescue => e
    log_execution_error(e)
    retry_execution

  # For any other non-StandardError Exceptions (like SystemExit, NoMemoryError, etc.), log them and exit.
  rescue Exception => e # rubocop:disable Lint/RescueException
    log_execution_error(e)
    raise
  ensure
    ActiveSupport::CurrentAttributes.clear_all
  end

  def eval_job_method
    Rails.logger.info "execute #{job.method} (try_count #{try_count})..."
    eval job.method # rubocop:disable Security/Eval
    Rails.logger.info "ended #{job.method} took: #{since_started} seconds."
  end

  def log_execution_error(e)
    error_description = e.is_a?(StandardError) ? 'error' : 'a non standard error'

    Rails.logger.error "execute #{job.method} (try_count #{try_count}) exited with #{error_description} #{e.inspect} in: #{since_started} seconds."
  end

  def mark_as_started
    @started_at = Time.current

    job.update!(
      last_run:      started_at,
      pid:           Thread.current.object_id,
      status:        'ok',
      error_message: '',
    )
  end

  def since_started
    Time.current - started_at
  end

  def retry_execution
    @try_count += 1

    # reset error counter if to old
    if try_run_time < 5.minutes.ago
      @try_count = 0
    end

    if @try_count > TRY_COUNT_MAX
      retry_limit_reached

      return
    end

    interruptible_sleep(try_count) if Rails.env.production?
    return if BackgroundServices.shutdown_requested

    execute
  end

  def retry_limit_reached
    error = "Failed to run #{job.method} after #{try_count} tries."
    Rails.logger.error error

    job.update!(
      error_message: error,
      status:        'error',
      active:        false,
    )

    raise BackgroundServices::Service::ProcessScheduledJobs::RetryLimitReachedError.new(job), "Scheduler #{job.name} reached retry limit while being executed"
  end
end
