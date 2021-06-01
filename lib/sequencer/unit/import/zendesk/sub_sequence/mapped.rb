# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module SubSequence
          module Mapped
            module ClassMethods

              def resource_map
                :"#{resource_klass.underscore}_map"
              end

              def inherited(base)
                super

                base.provides(base.resource_map)

                base.extend(Forwardable)
                base.instance_delegate [:resource_map] => base
              end
            end

            def self.included(base)
              base.uses :client

              base.extend(ClassMethods)
            end

            def process
              state.provide(resource_map) do
                process_sub_sequence
                mapping
              end
            end

            private

            def expecting
              raise 'Missing implementation of expecting method'
            end

            def collection_provider
              client
            end

            def process_sub_sequence
              resource_iteration do |resource|

                expected_value = expected(resource)

                next if expected_value.blank?

                mapping[resource.id] = mapping_value(expected_value)
              end
            end

            def expected(resource)
              result = sub_sequence(resource)
              result[expecting]
            end

            def sub_sequence(resource)
              ::Sequencer.process(sequence_name,
                                  parameters: default_params.merge(
                                    resource: resource
                                  ),
                                  expecting:  [expecting])
            end

            def mapping_value(expected_value)
              expected_value
            end

            def mapping
              @mapping ||= {}
            end
          end
        end
      end
    end
  end
end
