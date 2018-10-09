class Sequencer
  class Unit
    module Import
      module Zendesk
        module TicketField
          class CheckCustom < Sequencer::Unit::Base

            uses :resource, :model_class
            provides :action

            def process
              return if custom?

              state.provide(:action, :skipped)
            end

            private

            def custom?
              model_class.column_names.exclude?(attribute)
            end

            def attribute
              mapping.fetch(resource.type, resource.type)
            end

            def mapping
              {
                'subject'        => 'title',
                'description'    => 'note',
                'status'         => 'state_id',
                'tickettype'     => 'type',
                'priority'       => 'priority_id',
                'basic_priority' => 'priority_id',
                'group'          => 'group_id',
                'assignee'       => 'owner_id',
              }.freeze
            end
          end
        end
      end
    end
  end
end
