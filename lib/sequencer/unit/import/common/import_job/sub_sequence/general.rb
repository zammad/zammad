require 'sequencer/mixin/sub_sequence'

class Sequencer
  class Unit
    module Import
      module Common
        module ImportJob
          module SubSequence
            class General < Sequencer::Unit::Base
              include ::Sequencer::Mixin::SubSequence

              uses :import_job

              def process
                resource_sequence
              end

              private

              # INFO: Cache results via `@sequence ||= ...`, if needed
              def sequence
                raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
              end

              # INFO: Cache results via `@resources ||= ...`, if needed
              def resources
                raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
              end

              def default_parameters
                {
                  dry_run:    import_job.dry_run,
                  import_job: import_job,
                }
              end

              def resource_sequence
                return if resources.blank?

                defaults = default_parameters

                resources.each do |resource|

                  arguments = {
                    parameters: defaults.merge(resource: resource)
                  }

                  yield resource, arguments if block_given?

                  arguments[:parameters][:resource] = arguments[:parameters][:resource].with_indifferent_access

                  result = sub_sequence(sequence, arguments)

                  processed(result)
                end
              end

              def processed(_result)
              end
            end
          end
        end
      end
    end
  end
end
