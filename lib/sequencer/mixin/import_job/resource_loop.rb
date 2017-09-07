require 'sequencer/mixin/sub_sequence'

class Sequencer
  module Mixin
    module ImportJob
      module ResourceLoop
        include ::Sequencer::Mixin::SubSequence

        private

        def resource_sequence(sequence_name, items)
          default_params = {
            dry_run:    import_job.dry_run,
            import_job: import_job,
          }

          items.each do |item|
            resource_params = {}
            if block_given?
              resource_params = yield item
            else
              resource_params[:resource] = item
            end

            resource_params[:resource] = resource_params[:resource].with_indifferent_access

            sub_sequence(sequence_name,
                         parameters: default_params.merge(resource_params))
          end

          # store possible unsaved values in result e.g. statistics
          import_job.save!
        end
      end
    end
  end
end
