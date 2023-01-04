# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Common::Provider::Fallback < Sequencer::Unit::Common::Provider::Attribute

  private

  def ignore?
    state.provided?(attribute) || super
  end
end
