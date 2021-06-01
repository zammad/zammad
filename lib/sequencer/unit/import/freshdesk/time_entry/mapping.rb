# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module TimeEntry
          class Mapping < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

            uses :resource, :id_map
            provides :action

            def process
              provide_mapped do
                {
                  time_unit:     time_unit,
                  ticket_id:     ticket_id,
                  created_by_id: agent_id,
                  created_at:    resource['created_at'],
                  updated_at:    resource['updated_at'],
                }
              end
            rescue TypeError => e
              # TimeTracking is not available in the plans: Sprout, Blossom
              # In this case `resource`s value is `["code", "require_feature"]`
              # See:
              # - Ticket# 1077135
              # - https://support.freshdesk.com/support/solutions/articles/37583-keeping-track-of-time-spent
              logger.debug { e }
              state.provide(:action, :skipped)
            end

            private

            def time_unit
              hours, minutes = resource['time_spent'].match(%r{(\d{2}):(\d{2})}).captures
              (hours.to_i * 60) + minutes.to_i
            end

            def ticket_id
              id_map['Ticket'][resource['ticket_id']]
            end

            def agent_id
              id_map['User'][resource['agent_id']]
            end
          end
        end
      end
    end
  end
end
