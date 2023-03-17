# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class ImportJob < Backend
      TIMEOUT = 5.minutes

      def run_health_check
        failed_imports
        stuck_imports
      end

      private

      def import_backends
        ::ImportJob.backends
      end

      def failed_imports
        import_backends.each { |backend| single_failed_import(backend) }
      end

      def failed_import_job(backend)
        ::ImportJob
          .where(name: backend, dry_run: false)
          .where('finished_at >= ?', TIMEOUT.ago)
          .limit(1)
          .first
      end

      def single_failed_import(backend)
        job = failed_import_job(backend)

        return if job.blank?
        return if !job.result.is_a?(Hash)

        error_message = job.result[:error]
        return if error_message.blank?

        response.issues.push "Failed to run import backend '#{backend}'. Cause: #{error_message}"
      end

      def stuck_imports
        import_backends.each { |backend| single_stuck_import(backend) }
      end

      def stuck_import_job(backend)
        ::ImportJob
          .where(name: backend, dry_run: false, finished_at: nil)
          .where('updated_at <= ?', TIMEOUT.ago)
          .limit(1)
          .first
      end

      def single_stuck_import(backend)
        job = stuck_import_job(backend)

        return if job.blank?

        response.issues.push "Stuck import backend '#{backend}' detected. Last update: #{job.updated_at}"
      end
    end
  end
end
