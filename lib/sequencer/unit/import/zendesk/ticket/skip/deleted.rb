# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

                logger.info { "Skipping. Zendesk Ticket ID '#{resource.id}' is in 'deleted' state." }
                state.provide(:action, :skipped)
              end
            end
          end
        end
      end
    end
  end
end
