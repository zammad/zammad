# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class Service
    class ProcessDelayedJobs
      class CleanupAction
        extend ::Mixin::StartFinishLogger

        attr_reader :job

        def self.cleanup_delayed_jobs(after)
          log_start_finish(:info, "Cleanup of left over locked delayed jobs #{after}") do

            scope(after).each do |job|
              log_start_finish(:info, "Checking left over delayed job #{job.inspect}") do
                CleanupAction.new(job).cleanup
              end
            end
          end
        end

        private_class_method def self.scope(after)
          ::Delayed::Job.where('updated_at < ?', after).where.not(locked_at: nil)
        end

        def initialize(job)
          @job = job
        end

        def cleanup
          return if job.locked_at.blank?

          if reschedulable?
            job.unlock
            job.save
          else
            job.destroy
          end

          Rails.logger.warn "#{action_name} locked delayed job: #{job_name}"
        end

        private

        def action_name
          reschedulable? ? 'Rescheduling' : 'Destroyed'
        end

        def job_name
          job_name = job.name

          if (object_id = job.payload_object.try(:object).try(:id))
            job_name += " (id: #{object_id})"
          end

          if job.payload_object.respond_to?(:args)
            job_name += " - ARGS: #{payload_object.args.inspect}"
          end

          job_name
        end

        def reschedulable?
          @reschedulable ||= job.payload_object.try(:object).try(:reschedule?, job)
        end
      end
    end
  end
end
