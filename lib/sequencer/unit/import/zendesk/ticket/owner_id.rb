class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          class OwnerID < Sequencer::Unit::Common::Provider::Named

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
