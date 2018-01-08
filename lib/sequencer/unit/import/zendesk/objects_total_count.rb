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

          def request(object)
            return tickets if object == 'Tickets'
            generic(object)
          end

          def generic(object)
            client.send(object.to_s.underscore.to_sym)
          end

          # this special ticket logic is needed since Zendesk archives tickets
          # after 120 days and doesn't return them via the client.tickets
          # endpoint as described here:
          # https://github.com/zammad/zammad/issues/558#issuecomment-267951351
          # the proper way is to use the 'incremental' endpoint which is not available
          # via the ruby gem yet but a pull request is pending:
          # https://github.com/zendesk/zendesk_api_client_rb/pull/287
          # the following workaround is needed to use this functionality
          # Counting Tickets has the limitations that max. 1000 are returned
          # that's why we need to update the number when it's exceeded while importing
          def tickets
            ZendeskAPI::Collection.new(
              client,
              ZendeskAPI::Ticket,
              path: 'incremental/tickets?start_time=1'
            )
          end
        end
      end
    end
  end
end
