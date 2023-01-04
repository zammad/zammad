# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Workaround for ActiveJob not supporting per-job timeouts with delayed_job.
#
# delayed_job does support this (https://github.com/collectiveidea/delayed_job#custom-jobs),
#   but since ActiveJob's adapter places a JobWrapper class around the jobs, it fails to work.
#
# Solve this by delegating that method to the actual job class instead.

# Set the maximum possible max_run_time for any job to a high value, and set a sensible default
#   in ApplicationJob.max_run_time. Then specific jobs like AsyncImportJob can override this with a
#   higher value.
Delayed::Worker.max_run_time = 7.days

module ActiveJob
  module QueueAdapters
    class DelayedJobAdapter
      class JobWrapper
        def max_run_time
          job_data['job_class'].constantize.max_run_time
        end
      end
    end
  end
end
