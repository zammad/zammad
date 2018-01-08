class Sequencer
  class Unit
    module Import
      module Zendesk
        module ObjectAttribute
          class Add < Sequencer::Unit::Base

            uses :model_class, :sanitized_name, :resource
            provides :instance

            def process
              state.provide(:instance) do
                backend_class.new(model_class, sanitized_name, resource)
              end
            end

            def backend_class
              "Import::Zendesk::ObjectAttribute::#{resource.type.capitalize}".constantize
            end
          end
        end
      end
    end
  end
end
