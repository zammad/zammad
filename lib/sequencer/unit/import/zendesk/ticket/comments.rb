# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          class Comments < Sequencer::Unit::Import::Zendesk::SubSequence::TicketSubObject

            uses :user_map

            private

            def default_params
              super.merge(
                user_map: user_map,
              )
            end
          end
        end
      end
    end
  end
end
