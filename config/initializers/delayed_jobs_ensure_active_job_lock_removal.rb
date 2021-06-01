# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'delayed_job'

module Delayed
  class Job < ::ActiveRecord::Base

    after_destroy :remove_active_job_lock

    def remove_active_job_lock
      # only ActiveJob Delayed::Jobs can have a lock
      return if !payload_object.is_a?(::ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper)

      # deserialize ActiveJob and load it's arguments to generate the lock_key
      active_job = ::ActiveJob::Base.deserialize(payload_object.job_data)

      # ActiveJob that is not an HasActiveJobLock has no lock
      return if !active_job.is_a?(HasActiveJobLock)

      begin
        active_job.arguments = ::ActiveJob::Arguments.deserialize(active_job.instance_variable_get(:@serialized_arguments))
      rescue => e
        active_job.arguments = nil
        Rails.logger.error e
      end

      # remove possible lock
      active_job.release_active_job_lock!
    end
  end
end
