# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ApplicationJob
  module HasDelayedJobMonitoringCompatibilty
    extend ActiveSupport::Concern

    included do
      # We (currently) rely on Delayed::Job#attempts to check for stuck backends
      # e.g. in the MonitoringController.
      # This is a workaround to sync ActiveJob#executions to Delayed::Job#attempts
      # until we resolve this dependency.
      after_enqueue do |job|
        # skip update of `attempts` attribute if job wasn't queued because of ActiveJobLock
        #(another job with same lock key got queued before this job could be retried)
        next if job.provider_job_id.blank?

        # update the column right away without loading Delayed::Job record
        # see: https://stackoverflow.com/a/34264580
        Delayed::Job.where(id: job.provider_job_id).update_all(attempts: job.executions) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end
end
