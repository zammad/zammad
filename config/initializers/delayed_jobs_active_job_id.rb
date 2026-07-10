# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'delayed_job'

module Delayed
  class Job < ::ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord

    # Keeps the `active_job_id` column in sync with the ActiveJob `job_id`
    # embedded in `handler`, so callers (e.g. ActiveJobLock#related_job) can
    # look up the related Delayed::Job record with a plain equality lookup
    # instead of an expensive `handler LIKE '%...%'` scan.
    before_save :set_active_job_id, if: :handler_changed?

    # Extracts the ActiveJob `job_id` from the YAML-serialized `handler` column.
    #
    # @return [String, nil] the ActiveJob job_id, or nil if this Delayed::Job
    #   is not backed by ActiveJob (or the handler cannot be deserialized)
    def active_job_id_from_handler
      return if !payload_object.is_a?(::ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper)

      payload_object.job_data['job_id']
    rescue Delayed::DeserializationError
      nil
    end

    private

    def set_active_job_id
      # When migrating from an old system, an older migration may try to queue a job
      # before the `active_job_id` column has been added. In that case, we skip setting it.
      return if Delayed::Job.column_names.exclude?('active_job_id')

      self.active_job_id = active_job_id_from_handler
    end
  end
end
