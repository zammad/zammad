class Sequencer
  class Unit
    module Import
      module Zendesk
        class Organizations < Sequencer::Unit::Import::Zendesk::SubSequence::Object

          private

          def resource_iteration_method
            :all!
          end
        end
      end
    end
  end
end
