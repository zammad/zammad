class Sequencer
  class Unit
    module Import
      module Zendesk
        module Group
          class Mapping < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

            uses :resource

            def process
              provide_mapped do
                {
                  name:   resource.name,
                  active: !resource.deleted,
                }
              end
            end
          end
        end
      end
    end
  end
end
