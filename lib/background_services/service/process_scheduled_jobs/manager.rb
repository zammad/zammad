# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class Service
    class ProcessScheduledJobs
      class Manager
        attr_reader :job, :jobs_container

        def initialize(job, jobs_container)
          @job            = job
          @jobs_container = jobs_container
        end

        def run
          return if skip?

          jobs_container[job.id] = start
        end

        private

        def skip?
          return true if BackgroundServices.shutdown_requested

          return true if skip_already_running?

          # check job.last_run
          return true if skip_job_last_run?

          # timeplan is optional
          # but if timeplan is present
          return true if skip_job_timeplan?

          false
        end

        def skip_already_running?
          return false if thread.blank?

          status = thread.try(:status)

          if status.blank?
            invalid_thread_log(thread, status)
            jobs_container.delete(job.id)
            return false
          end

          log_already_running(status)
          true
        end

        def log_already_running(status)
          Rails.logger.info "Running job thread for '#{job.name}' (#{job.method}) status is: #{status}"
        end

        def skip_job_last_run?
          return false if !job.last_run || !job.period

          job.last_run > (Time.zone.now - job.period)
        end

        def skip_job_timeplan?
          return false if job.timeplan.blank?

          !job.in_timeplan?(Time.zone.now)
        end

        def thread
          jobs_container[job.id]
        end

        def start
          Thread.new do
            Thread.current.name = "ProcessScheduledJobs manager thread for job \"#{job.name}\" (#{job.id})"

            Rails.application.executor.wrap do
              start_in_thread
            end
          rescue => e
            Rails.logger.error e
            jobs_container.delete(job.id)
          end
        end

        def start_in_thread
          ApplicationHandleInfo.use('scheduler') do
            Rails.logger.debug { "Started job thread for '#{job.name}' (#{job.method})..." }
            JobExecutor.run(job)
            wrapup
          end
        end

        def wrapup
          job.update! pid: ''

          Rails.logger.debug { " ...stopped thread for '#{job.method}'" }

          # release thread lock and remove thread handle
          jobs_container.delete(job.id)
        end

        def build_invalid_thread_log(thread, status)
          if thread.respond_to?(:status)
            return "Invalid thread stored for job '#{job.name}' (#{job.method}): #{thread.inspect}. Deleting and resting job."
          end

          how = if status.nil?
                  'via an exception'
                elsif status == false
                  'normally'
                else
                  'unknownly'
                end

          "Job thread terminated #{how} found for '#{job.name}' (#{job.method}). This should not happen. Please report."
        end

        def invalid_thread_log(thread, status)
          Rails.logger.error build_invalid_thread_log(thread, status)
        end
      end
    end
  end
end
