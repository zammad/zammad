# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ActiveJobLock < ActiveRecord::Base

  def of?(active_job)
    active_job.job_id == active_job_id
  end

  def peform_pending?
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
end
