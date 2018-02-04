class Sequencer
  class Unit
    module Import
      module Zendesk
        module SubSequence
          class TicketSubObject < Sequencer::Unit::Import::Zendesk::SubSequence::SubObject

            private

            def sequence_name
              "Import::Zendesk::Ticket::#{resource_klass}"
            end
          end
        end
      end
    end
  end
end
