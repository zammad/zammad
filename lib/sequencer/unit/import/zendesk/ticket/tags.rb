# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
