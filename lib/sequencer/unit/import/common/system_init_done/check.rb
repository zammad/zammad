# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::SystemInitDone::Check < Sequencer::Unit::Base

  def process
    return if !Setting.get('system_init_done')

    raise 'System is already system_init_done!'
  end
end
