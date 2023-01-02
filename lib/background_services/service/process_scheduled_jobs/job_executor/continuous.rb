# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices::Service::ProcessScheduledJobs
  class JobExecutor::Continuous < JobExecutor
    LOOP_LIMIT = 1_800

    def run
      run_loop
    end

    protected

    def run_loop
      # only do a certain amount of loops in this thread
      LOOP_LIMIT.times do
        execute

        reload_job

        break if !job.runs_as_persistent_loop?

        # wait until next run
        sleep job.period
      end
    end

    def reload_job
      updated_job = Scheduler.lookup(id: job.id)

      if !updated_job
        raise SchedulerObjectGoneError.new(job), "Scheduler #{job.name} was removed while it was being executed"
      end

      @job = updated_job
    end
  end
end
