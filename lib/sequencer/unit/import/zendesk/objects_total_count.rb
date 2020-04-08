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
              stats[object] = object_diff(object)
            end
          end

          def object_diff(object)
            collection_name = object.to_s.underscore
            collection      = client.send collection_name

            empty_diff.merge(
              total: collection.count!
            )
          end
        end
      end
    end
  end
end
