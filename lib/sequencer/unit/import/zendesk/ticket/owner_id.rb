# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          class OwnerId < Sequencer::Unit::Common::Provider::Named

            uses :resource, :user_map

            private

            def owner_id
              user_map.fetch(resource.assignee_id, 1)
            end
          end
        end
      end
    end
  end
end
