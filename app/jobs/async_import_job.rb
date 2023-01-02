# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class AsyncImportJob < ApplicationJob

  # See config/initializers/delayed_jobs_timeout_per_job.rb for details.
  def self.max_run_time
    7.days
  end

  def perform(import_job)
    import_job.start
  end
end
