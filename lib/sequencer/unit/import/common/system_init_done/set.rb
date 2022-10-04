# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::SystemInitDone::Set < Sequencer::Unit::Base

  def process
    Setting.set('system_init_done', true)
  end
end
