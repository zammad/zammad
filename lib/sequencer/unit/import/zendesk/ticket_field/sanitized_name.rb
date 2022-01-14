# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module TicketField
          class SanitizedName < Sequencer::Unit::Import::Common::ObjectAttribute::SanitizedName

            uses :resource

            private

            def unsanitized_name
              # Model ID
              # Model IDs
              # Model / Name
              # Model Name
              # Model Name?
              # Model::Name
              resource.title
            end
          end
        end
      end
    end
  end
end
