class Sequencer
  class Unit
    module Common
      module Provider
        class Fallback < Sequencer::Unit::Common::Provider::Attribute

          private

          def ignore?
            state.provided?(attribute) || super
          end
        end
      end
    end
  end
end
