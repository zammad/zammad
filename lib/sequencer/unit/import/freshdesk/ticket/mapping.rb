class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Ticket
          class Mapping < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

            uses :resource, :id_map

            PRIORITY_MAP = {
              1 => ::Ticket::Priority.find_by(name: '1 low').id, # low
              2 => ::Ticket::Priority.find_by(name: '2 normal').id, # medium
              3 => ::Ticket::Priority.find_by(name: '3 high').id, # high
              4 => ::Ticket::Priority.find_by(name: '3 high').id, # urgent
            }.freeze

            STATE_MAP = {
              2 => ::Ticket::State.find_by(name: 'open').id, # open
              3 => ::Ticket::State.find_by(name: 'open').id, # pending
              4 => ::Ticket::State.find_by(name: 'closed').id, # resolved
              5 => ::Ticket::State.find_by(name: 'closed').id, # closed
            }.freeze

            def process # rubocop:disable Metrics/AbcSize
              provide_mapped do
                {
                  title:       resource['subject'],
                  number:      resource['id'],
                  group_id:    group_id,
                  priority_id: PRIORITY_MAP[resource['priority']],
                  state_id:    STATE_MAP[resource['status']],
                  owner_id:    owner_id,
                  customer_id: customer_id,
                  created_at:  resource['created_at'],
                  updated_at:  resource['updated_at'],
                }
              end
            end

            private

            def group_id
              id_map.dig('Group', resource['group_id']) || ::Group.find_by(name: 'Support')&.id || 1
            end

            def customer_id
              id_map['User'][resource['requester_id']]
            end

            def owner_id
              id_map['User'][resource['responder_id']]
            end
          end
        end
      end
    end
  end
end
