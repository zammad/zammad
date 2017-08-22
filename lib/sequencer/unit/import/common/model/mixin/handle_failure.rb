class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Mixin
            module HandleFailure

              def self.included(base)
                base.provides :exception, :instance_action
              end

              def handle_failure(e)
                logger.error(e)
                state.provide(:exception, e)
                state.provide(:instance_action, :failed)
              end
            end
          end
        end
      end
    end
  end
end
