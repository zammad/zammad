# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ApplicationJob
  module HasCustomLogging
    extend ActiveSupport::Concern

    # ActiveJob default logging is to verbose in default setups.
    # Therefore we overwrite the default `ActiveJob::Logging::LogSubscriber` with a custom version.
    # This is currently done in an initializer because Rails 5.2 does not support detaching subscribers.
    # The custom version comes with two changes:
    # - Don't log info level lines
    # - Log (info) that an ActiveJob was not enqueued in case there is already one queued with the same ActiveJobLock
    class LogSubscriber < ActiveJob::Logging::LogSubscriber

      # ATTENTION: Uncomment this line to enable info logging again
      def info(*); end

      def enqueue(event)
        super if job_enqueued?(event)
      end

      def enqueue_at(event)
        super if job_enqueued?(event)
      end

      private

      def job_enqueued?(event)
        job = event.payload[:job]

        # having a provider_job_id means that the job was enqueued
        return true if job.provider_job_id.present?

        # we're only interested to log not enqueued lock-jobs for now
        return false if !job.is_a?(HasActiveJobLock)

        info do
          "Won't enqueue #{job.class.name} (Job ID: #{job.job_id}) to #{queue_name(event)}" + args_info(job) + " because of already existing Job with Lock Key '#{job.lock_key}'."
        end

        # don't log regular enqueue log lines
        false
      end
    end
  end
end

ApplicationJob::HasCustomLogging::LogSubscriber.attach_to :active_job
