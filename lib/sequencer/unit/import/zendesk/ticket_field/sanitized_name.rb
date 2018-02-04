class Sequencer
  class Unit
    module Import
      module Zendesk
        module TicketField
          class SanitizedName < Sequencer::Unit::Import::Common::ObjectAttribute::SanitizedName
            prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

            skip_action :skipped

            uses :resource, :action

            private

            def unsanitized_name
              # Model ID
              # Model IDs
              # Model / Name
              # Model Name
              resource.title
            end
          end
        end
      end
    end
  end
end
