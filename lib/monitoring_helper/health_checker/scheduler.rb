# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

          response.issues.push "scheduler may not run (last execution of #{scheduler.method} #{time_ago_in_words(scheduler.last_run)} ago) - please contact your system administrator"
          break
        end
      end

      def last_execution_scope
        ::Scheduler
          .where('active = ? AND period > 300', true)
          .where.not(last_run: nil)
          .order(last_run: :asc, period: :asc)
      end

      def last_execution_deadline(scheduler)
        return scheduler.last_run if scheduler.timeplan.blank?

        calculator = TimeplanCalculation.new(scheduler.timeplan, Setting.get('timezone_default_sanitized'))
        intermediary = calculator.next_at(scheduler.last_run + 10.minutes)
        calculator.next_at(intermediary + 10.minutes)
      end

      def last_execution_on_time?(scheduler)
        return false if scheduler.last_run.blank?

        last_execution_deadline(scheduler) + scheduler.period.seconds >= LAST_EXECUTION_TOLERANCE.ago
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
