# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module ObjectAttribute
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
              resource['key']
            end
          end
        end
      end
    end
  end
end
