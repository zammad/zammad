# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# In previous versions of Zammad we used Delayed::Job exclusively
# for performing background jobs. Delayed::Job was therefore in
# charge of scheduling, retrying and executing background jobs.
# After the (partly) migration to Rails ActiveJob this has changed.
# Now ActiveJob is in charge of scheduling and retrying jobs
# while Delayed::Job is still in charge of executing the jobs (assigned to it).
# That leads to an issue where Delayed::Job now falls back to the default
# of 25 retries for a failed job.
# This is not wanted since retries are handled by ActiveJob.
# Therefore the JobWrapper (the class/handler that gets queued) has to define
# max_attempts to be only one. A failing ActiveJob will now be retried as
# often as configured by ActiveJob and then an exception will be raised by
# ActiveJob with the last error message. This message will be rescued by
# Delayed::Job which will see that there are no more attempts wanted and
# will record and handle it as a failed job.
module ActiveJob
  module QueueAdapters
    class DelayedJobAdapter
      class JobWrapper
        def max_attempts
          1
        end
      end
    end
  end
end
