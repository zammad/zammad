# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::SystemInitDone::Set < Sequencer::Unit::Base

  def process
    Setting.set('system_init_done', true)
  end
end
