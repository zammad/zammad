# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class Service
    class ProcessScheduledJobs < Service
      SLEEP_AFTER_JOB_START = 1.second
      SLEEP_AFTER_LOOP = 10.seconds

      attr_reader :jobs_started

      def initialize(...)
        @jobs_started = Concurrent::Hash.new
        super
      end

      def launch
        loop do
          break if BackgroundServices.shutdown_requested

          Rails.logger.info 'ProcessScheduledJobs running...'

          run_jobs

          interruptible_sleep SLEEP_AFTER_LOOP
        end

        # Wait for threads to finish for a clean shutdown.
        jobs_started.each(&:join)
      end

      private

      def run_jobs
        scope.each do |job|
          break if BackgroundServices.shutdown_requested

          result = Manager.new(job, jobs_started).run

          interruptible_sleep SLEEP_AFTER_JOB_START if result
        end
      end

      def scope
        # changes in sub threads will not update the rails
        # cache so we need to be sure that the scheduler get
        # updated last_run values, so they don't run all the time
        # https://github.com/zammad/zammad/issues/4167
        Scheduler.clear_query_caches_for_current_thread
        Scheduler.where(active: true).reorder(prio: :asc)
      end
    end
  end
end
