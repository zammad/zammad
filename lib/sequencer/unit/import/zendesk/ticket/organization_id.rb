# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          class OrganizationID < Sequencer::Unit::Common::Provider::Named

            uses :resource, :organization_map

            private

            def organization_id
              organization_map[resource.organization_id]
            end
          end
        end
      end
    end
  end
end
