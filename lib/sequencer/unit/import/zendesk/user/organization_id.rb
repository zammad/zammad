# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module User
          class OrganizationId < Sequencer::Unit::Common::Provider::Named

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
