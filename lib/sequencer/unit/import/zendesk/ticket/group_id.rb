# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          class GroupId < Sequencer::Unit::Common::Provider::Named

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
