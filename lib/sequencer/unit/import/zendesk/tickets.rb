# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        class Tickets < Sequencer::Unit::Import::Zendesk::SubSequence::Object
          include ::Sequencer::Unit::Import::Zendesk::Mixin::IncrementalExport

          uses :user_map, :organization_map, :group_map, :ticket_field_map

          private

          def default_params
            super.merge(
              user_map:         user_map,
              group_map:        group_map,
              organization_map: organization_map,
              ticket_field_map: ticket_field_map,
            )
          end
        end
      end
    end
  end
end
