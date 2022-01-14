# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module User
          class OrganizationId < Sequencer::Unit::Common::Provider::Named

            uses :resource, :id_map

            private

            def organization_id
              remote_id = resource['organization']&.fetch('id')
              return if remote_id.blank?

              id_map['Organization'][remote_id]
            end
          end
        end
      end
    end
  end
end
