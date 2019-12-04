require 'delayed_job'

module Delayed
  class Job < ::ActiveRecord::Base

    after_destroy :remove_active_job_lock

    def remove_active_job_lock
      # only ActiveJob Delayed::Jobs can have a lock
      return if !payload_object.is_a?(::ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper)

      # deserialize ActiveJob and load it's arguments to generate the lock_key
      active_job           = ::ActiveJob::Base.deserialize(payload_object.job_data)
      active_job.arguments = ::ActiveJob::Arguments.deserialize(active_job.instance_variable_get(:@serialized_arguments))

      # remove possible lock
      active_job.try(:release_active_job_lock!)
    end
  end
end
