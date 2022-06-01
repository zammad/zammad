# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class Service
    class ProcessScheduledJobs < Service
      SLEEP_AFTER_JOB_START = 10.seconds
      SLEEP_AFTER_LOOP = 60.seconds

      attr_reader :jobs_started

      def initialize
        super
        @jobs_started = Concurrent::Hash.new
      end

      def launch
        loop do
          Rails.logger.info 'Scheduler running...'

          run_jobs

          sleep SLEEP_AFTER_LOOP
        end
      end

      private

      def run_jobs
        scope.each do |job|
          Manager.new(job, jobs_started).run
          sleep SLEEP_AFTER_JOB_START
        end
      end

      def scope
        Scheduler.where(active: true).order(prio: :asc)
      end
    end
  end
end
