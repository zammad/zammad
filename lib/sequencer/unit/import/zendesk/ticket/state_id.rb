# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          class StateId < Sequencer::Unit::Common::Provider::Named

            uses :resource

            private

            def state_id
              ::Ticket::State.select(:id).find_by(name: local).id
            end

            def local
              mapping.fetch(resource.status, resource.status)
            end

            def mapping
              {
                'pending' => 'pending reminder',
                'solved'  => 'closed',
                'deleted' => 'removed',
                'hold'    => 'open'
              }.freeze
            end
          end
        end
      end
    end
  end
end
