# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
