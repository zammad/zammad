# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module User
          class OrganizationID < Sequencer::Unit::Common::Provider::Named

            uses :resource, :organization_map

            private

            def organization_id
              remote_id = resource.organization_id
              return if remote_id.blank?

              organization_map[remote_id]
            end
          end
        end
      end
    end
  end
end
