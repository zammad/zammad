# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Common
      class UnsetAttributes < Sequencer::Unit::Base

        def process
          uses = self.class.uses
          return if uses.blank?

          uses.each do |attribute|
            state.unset(attribute)
          end
        end
      end
    end
  end
end
