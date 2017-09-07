class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Mixin
            module SkipOnSkippedInstance

              def self.prepended(base)
                base.uses :instance_action
              end

              def process
                if instance_action == :skipped
                  logger.debug("Skipping. Attribute 'instance_action' is set to :skipped.")
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
