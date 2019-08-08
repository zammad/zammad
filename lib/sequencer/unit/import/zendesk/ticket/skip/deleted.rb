class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          module Skip
            class Deleted < Sequencer::Unit::Base

              uses :resource
              provides :action

              def process
                return if resource.status != 'deleted'

                state.provide(:action, :skipped)
              end
            end
          end
        end
      end
    end
  end
end
