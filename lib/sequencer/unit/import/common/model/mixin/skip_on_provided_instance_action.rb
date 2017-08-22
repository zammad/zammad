class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Mixin
            module SkipOnProvidedInstanceAction

              def process
                if state.provided?(:instance_action)
                  logger.debug("Skipping. Attribute 'instance_action' already provided.")
                else
                  super
                end
              end
            end
          end
        end
      end
    end
  end
end
