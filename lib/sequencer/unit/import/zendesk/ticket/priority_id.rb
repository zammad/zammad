# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          class PriorityID < Sequencer::Unit::Common::Provider::Named

            uses :resource

            private

            def priority_id
              ::Ticket::Priority.select(:id).find_by(name: local).id
            end

            def local
              mapping.fetch(resource.priority, mapping[nil])
            end

            def mapping
              {
                'low'    => '1 low',
                nil      => '2 normal',
                'normal' => '2 normal',
                'high'   => '3 high',
                'urgent' => '3 high',
              }.freeze
            end
          end
        end
      end
    end
  end
end
