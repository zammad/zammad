# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class Service
    class BaseDelayedJobs < Service
      SLEEP_IF_EMPTY = 4.seconds

      def self.max_workers
        16
      end

      def self.max_worker_threads
        16
      end

      def self.queues
        raise 'not implemented'
      end

      def self.pre_launch
        start_time = Time.zone.now

        CleanupAction.cleanup_delayed_jobs(start_time, queues:)

        start_time
      end

      def launch
        Delayed::Worker.reset

        loop do
          break if BackgroundServices.shutdown_requested

          result = nil

          realtime = Benchmark.realtime do
            Rails.logger.debug do
              format('*** worker thread, %<count>d in %<queues>s queues', # rubocop:disable Style/FormatStringToken
                     count:  ::Delayed::Job.where(queue: self.class.queues).count,
                     queues: self.class.queues)
            end

            # DelayedJob does not support SQL Query caching correctly
            ActiveRecord::Base.uncached do
              # ::Delayed::Worker#stop? is monkey patched by config/initializers/delayed_worker_stop.rb
              #   to ensure an early exit even during work_off().
              result = ::Delayed::Worker.new(queues: self.class.queues).work_off
            end
          end

          process_results(result, realtime)
        ensure
          ActiveSupport::CurrentAttributes.clear_all
        end
      end

      private

      def process_results(result, realtime)
        result.sum.zero? ? process_empty : process_busy(result, realtime)
      end

      def process_empty
        Rails.logger.debug do
          format('*** no jobs processed in %<queues>s, sleeping…', queues: self.class.queues) # rubocop:disable Style/FormatStringToken
        end
        interruptible_sleep SLEEP_IF_EMPTY
        Rails.logger.debug do
          format('*** worker thread loop processing %<queues>s queues', queues: self.class.queues) # rubocop:disable Style/FormatStringToken
        end
      end

      def process_busy(result, realtime)
        count = result.sum

        Rails.logger.debug do
          format('*** %<count>d jobs processed at %<jps>.4f j/s, %<failed>d failed in %<queues>s queues…\n', # rubocop:disable Style/FormatStringToken
                 count:  count,
                 queues: self.class.queues,
                 jps:    count / realtime,
                 failed: result.last)
        end
      end
    end
  end
end
