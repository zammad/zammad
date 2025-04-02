# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class Service
    class ProcessDelayedJobs < Service
      SLEEP_IF_EMPTY = 4.seconds

      def self.max_workers
        16
      end

      def self.pre_launch
        start_time = Time.zone.now

        CleanupAction.cleanup_delayed_jobs(start_time)
        ImportJob.cleanup_import_jobs(start_time)
      end

      def launch
        loop do
          break if BackgroundServices.shutdown_requested

          result = nil

          realtime = Benchmark.realtime do
            Rails.logger.debug { "*** worker thread, #{::Delayed::Job.count} in queue" }
            # ::Delayed::Worker#stop? is monkey patched by config/initializers/delayed_worker_stop.rb
            #   to ensure an early exit even during work_off().
            result = ::Delayed::Worker.new.work_off
          end

          process_results(result, realtime)
        end
      end

      private

      def process_results(result, realtime)
        count = result.sum

        if count.zero?
          interruptible_sleep SLEEP_IF_EMPTY
          Rails.logger.debug { '*** worker thread loop' }
        else
          Rails.logger.debug { format("*** #{count} jobs processed at %<jps>.4f j/s, %<failed>d failed ...\n", jps: count / realtime, failed: result.last) }
        end
      end
    end
  end
end
