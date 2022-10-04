# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Common::Provider::Fallback < Sequencer::Unit::Common::Provider::Attribute

  private

  def ignore?
    state.provided?(attribute) || super
  end
end
