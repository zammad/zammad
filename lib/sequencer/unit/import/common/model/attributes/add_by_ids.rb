class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Attributes
            class AddByIds < Sequencer::Unit::Base
              include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

              def process
                provide_mapped do
                  {
                    created_by_id: 1,
                    updated_by_id: 1,
                  }
                end
              end
            end
          end
        end
      end
    end
  end
end
