# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Attributes
            class AddByIds < Sequencer::Unit::Base
              include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped
              prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

              skip_any_action

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
