# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class Scheduler < Backend
      include ActionView::Helpers::DateHelper

      LAST_EXECUTION_TOLERANCE = 8.minutes

      def run_health_check
        last_execution
        none_running
        failed_jobs
      end

      private

      def last_execution
        last_execution_scope.each do |scheduler|
          next if last_execution_on_time?(scheduler)

          last_execution = time_ago_in_words(scheduler.last_run)

          next_execution_time = next_execution_time(scheduler)

          next_execution = if next_execution_time.future?
                             "in #{distance_of_time_in_words(Time.current, next_execution_time(scheduler))}"
                           else
                             'imminent'
                           end

          response.issues.push "scheduler may not run (last execution of #{scheduler.method} #{last_execution} ago, next execution #{next_execution}) - please contact your system administrator"
          break
        end
      end

      def last_execution_scope
        ::Scheduler
          .where('active = ? AND period > 300', true)
          .where.not(last_run: nil)
          .reorder(last_run: :asc, period: :asc)
      end

      def last_execution_deadline(scheduler)
        return scheduler.last_run if scheduler.timeplan.blank?

        calculator = scheduler.timeplan_calculation
        intermediary = calculator.next_at(scheduler.last_run + 10.minutes)
        calculator.next_at(intermediary + 10.minutes)
      end

      def last_execution_on_time?(scheduler)
        return false if scheduler.last_run.blank?

        last_execution_deadline(scheduler) + scheduler.period.seconds >= LAST_EXECUTION_TOLERANCE.ago
      end

      def next_execution_time(scheduler)
        if scheduler.timeplan.blank?
          return Time.current if scheduler.last_run.blank?

          return scheduler.last_run + scheduler.period
        end

        current_time = if scheduler.last_run
                         [Time.current, scheduler.last_run + scheduler.period].max
                       else
                         Time.current
                       end

        scheduler
          .timeplan_calculation
          .next_at(current_time)
      end

      def none_running
        return if ::Scheduler.where(active: true).where.not(last_run: nil).exists?

        response.issues.push 'scheduler not running'
      end

      def failed_jobs
        ::Scheduler.failed_jobs.each do |job|
          response.issues.push "Failed to run scheduled job '#{job.name}'. Cause: #{job.error_message}"
          response.actions.add(:restart_failed_jobs)
        end
      end
    end
  end
end
