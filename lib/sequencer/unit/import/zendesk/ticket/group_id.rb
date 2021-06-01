# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          class GroupID < Sequencer::Unit::Common::Provider::Named

            uses :resource, :group_map

            private

            def group_id
              group_map.fetch(resource.group_id, 1)
            end
          end
        end
      end
    end
  end
end
