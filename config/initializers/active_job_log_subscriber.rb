# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'active_job/log_subscriber'

# Patch `ActiveJob::LogSubscriber` so that:
#   - Lifecycle lines (`Enqueued` / `Performing` / `Performed` / `Retrying` / …),
#     which Rails emits at info level, drop to debug. Production logs stay quiet
#     while development still sees them when the logger runs at debug level.
#     Error and warn paths in the parent (failed enqueue, retry_stopped, discard)
#     are untouched and keep their original level.
#   - A debug "Won't enqueue" line is emitted for `HasActiveJobLock` jobs that
#     were skipped because of an already existing lock — useful when tracking
#     down job scheduling behavior without sprinkling `binding.pry` calls.
#
# Lives in an initializer (loaded once at boot, not reloaded in development) so
#   the `prepend` cannot accumulate multiple module copies in
#   `ActiveJob::LogSubscriber.ancestors` across autoload reloads.
module ActiveJobLogSubscriberOverrides

  # Redirects every `info`-level line emitted by the parent class to debug.
  #   The parent's `error` / `warn` calls bypass this and keep their level.
  def info(progname = nil, &)
    debug(progname, &)
  end

  def enqueue(event)
    super if job_enqueued?(event)
  end

  def enqueue_at(event)
    super if job_enqueued?(event)
  end

  private

  def job_enqueued?(event)
    job = event.payload[:job]

    # `provider_job_id` is present iff the adapter actually enqueued the job.
    return true if job.provider_job_id.present?

    # Only emit the custom line for `HasActiveJobLock` collisions — other halts
    #   (regular before_enqueue callbacks) are handled upstream.
    return false if !job.is_a?(HasActiveJobLock)

    debug do
      "Won't enqueue #{job.class.name} (Job ID: #{job.job_id}) to #{queue_name(event)}" \
        "#{args_info(job)} because of already existing Job with Lock Key '#{job.lock_key}'."
    end

    # Suppress the parent's regular "Enqueued ..." line for this case.
    false
  end
end

ActiveJob::LogSubscriber.prepend(ActiveJobLogSubscriberOverrides)
