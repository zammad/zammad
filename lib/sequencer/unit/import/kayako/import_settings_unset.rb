# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ImportSettingsUnset < Sequencer::Unit::Base
  def process
    Setting.set('import_kayako_endpoint_username', nil)
    Setting.set('import_kayako_endpoint_password', nil)
  end
end
