# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class JobRunJob < ApplicationJob
  include HasActiveJobLock

  def lock_key
    "#{self.class.name}/#{arguments[0]}"
  end

  def perform(job_id)
    job = Job.find_by(id: job_id)

    return if job.nil? || !job.runnable_on_demand?

    job.run(true)
  end
end
