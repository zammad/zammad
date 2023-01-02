# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::ImportMode::Unset < Sequencer::Unit::Base

  def process
    Setting.set('import_mode', false)
  end
end
