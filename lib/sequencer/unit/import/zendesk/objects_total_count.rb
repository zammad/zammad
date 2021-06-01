# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        class ObjectsTotalCount < Sequencer::Unit::Common::Provider::Attribute
          include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::EmptyDiff

          uses :client

          private

          def statistics_diff
            %i[Groups Users Organizations Tickets].each_with_object({}) do |object, stats|
              stats[object] = empty_diff.merge(
                total: request(object).count!
              )
            end
          end

          # the special "incremental_export" logic is needed because Zendesk
          # archives records and doesn't return them via e.g. client.tickets
          # endpoint as described here:
          # https://github.com/zammad/zammad/issues/558#issuecomment-267951351
          # Counting via the incremental_export endpoint has the limitations
          # that it returns max. 1000. That's why we need to update the total
          # number while importing in the resource loop
          def request(object)
            resource_class = "::ZendeskAPI::#{object.to_s.singularize}".safe_constantize
            if resource_class.respond_to?(:incremental_export)
              # read as: ::ZendeskAPI::Ticket.incremental_export(client, 1)
              resource_class.incremental_export(client, 1)
            else
              # read as: client.groups
              client.send(object.to_s.underscore.to_sym)
            end
          end
        end
      end
    end
  end
end
