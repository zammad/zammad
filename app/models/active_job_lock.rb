# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ActiveJobLock < ActiveRecord::Base

  def of?(active_job)
    active_job.job_id == active_job_id
  end

  def perform_pending?
    updated_at == created_at
  end

  def transfer_to(active_job)
    logger.debug { "Transferring ActiveJobLock with id '#{id}' from active_job_id '#{active_job_id}' to active_job_id '#{active_job_id}'." }

    reset_time_stamp = Time.zone.now
    update!(
      active_job_id: active_job.job_id,
      created_at:    reset_time_stamp,
      updated_at:    reset_time_stamp
    )
  end

  # This method is used to find the Delayed::Job record representing the ActiveJob associated with this lock.
  #
  # @return [Delayed::Job, nil] the related Delayed::Job record, or nil if not found
  def related_job
    case ActiveJob::Base.queue_adapter
    when ActiveJob::QueueAdapters::DelayedJobAdapter
      Delayed::Job
        .where(
          'handler LIKE :no_quotes OR handler LIKE :with_quotes',
          no_quotes:   "%job_id: #{active_job_id}%",
          with_quotes: "%job_id: '#{active_job_id}'%"
        ).first
    when ActiveJob::QueueAdapters::TestAdapter
      ActiveJob::Base.queue_adapter.enqueued_jobs.find { it['job_id'] == active_job_id }
    end
  end
end
