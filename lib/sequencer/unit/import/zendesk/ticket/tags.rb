# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          class Tags < Sequencer::Unit::Import::Zendesk::SubSequence::TicketSubObject
          end
        end
      end
    end
  end
end
