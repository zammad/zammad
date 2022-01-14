# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
