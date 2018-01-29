class Sequencer
  class Unit
    module Import
      module Common
        module SubSequence
          module Mixin
            module Base
              private

              def sequence
                raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
              end

              def sequence_name
                @sequence_name ||= sequence
              end

              def default_params
                {}
              end

              def default_parameter
                @default_parameter ||= default_params
              end

              def sequence_resource(resource)
                sequence_parameter            = default_parameter.dup
                sequence_parameter[:resource] = resource

                sequence_parameter = yield(sequence_parameter) if block_given?

                sequence_parameter[:resource] = sequence_parameter[:resource].to_h.with_indifferent_access

                ::Sequencer.process(sequence_name,
                                    parameters: sequence_parameter)
              end

              def sequence_resources(resources, &block)
                resources.each do |resource|
                  sequence_resource(resource, &block)
                end
              end
            end
          end
        end
      end
    end
  end
end
