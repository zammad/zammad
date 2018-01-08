class Sequencer
  class Unit
    module Import
      module Zendesk
        module Organization
          class CustomFields < Sequencer::Unit::Import::Zendesk::Common::CustomFields

            private

            def remote_fields
              resource.organization_fields
            end
          end
        end
      end
    end
  end
end
