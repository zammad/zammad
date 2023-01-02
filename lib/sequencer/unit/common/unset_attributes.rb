# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Common::UnsetAttributes < Sequencer::Unit::Base

  def process
    uses = self.class.uses
    return if uses.blank?

    uses.each do |attribute|
      state.unset(attribute)
    end
  end
end
