# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
