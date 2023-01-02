# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class DelayedJob < Backend
      FAILED_JOBS_THRESHOLD = 10
      TOTAL_JOBS_THRESHOLD  = 8_000
      TOTAL_JOBS_TIMEOUT = 15.minutes

      def run_health_check
        failed_jobs
        failed_with_attempts
        total_jobs
      end

      private

      def scope
        Delayed::Job.where('attempts > 0')
      end

      def failed_jobs
        count_failed_jobs = scope.count

        return if count_failed_jobs <= FAILED_JOBS_THRESHOLD

        response.issues.push "#{count_failed_jobs} failing background jobs"
      end

      def failed_with_attempts
        scope
          .order(:created_at)
          .limit(10)
          .each_with_object({}) { |elem, memo| map_single_failed_job(elem, memo) }
          .sort
          .each_with_index do |(job_name, job_data), index|
            response.issues.push "Failed to run background job ##{index + 1} '#{job_name}' #{job_data[:count]} time(s) with #{job_data[:attempts]} attempt(s)."
          end
      end

      def map_single_failed_job(job, hash)
        job_name = job_name(job)

        hash[job_name] ||= {
          count:    0,
          attempts: 0,
        }

        hash[job_name][:count]    += 1
        hash[job_name][:attempts] += job.attempts
      end

      def job_name(job)
        if job.instance_of?(Delayed::Backend::ActiveRecord::Job) && job.payload_object.respond_to?(:job_data)
          return job.payload_object.job_data['job_class']
        end

        job.name
      end

      def total_jobs
        total_jobs = Delayed::Job.where('created_at < ?', TOTAL_JOBS_TIMEOUT.ago).count

        return if total_jobs <= TOTAL_JOBS_THRESHOLD

        response.issues.push "#{total_jobs} background jobs in queue"
      end
    end
  end
end
