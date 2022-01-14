# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module ObjectAttribute
          class SanitizedName < Sequencer::Unit::Import::Common::ObjectAttribute::SanitizedName
            prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

            skip_any_action

            uses :resource

            private

            def unsanitized_name
              resource['key']
            end
          end
        end
      end
    end
  end
end
