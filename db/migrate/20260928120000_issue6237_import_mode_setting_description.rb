# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6237ImportModeSettingDescription < ActiveRecord::Migration[8.1]
  PREVIOUS_DESCRIPTION = 'Puts Zammad into import mode (disables some triggers).'.freeze
  NEW_DESCRIPTION      = 'Puts Zammad into import mode. This disables some triggers and denies access to all users without the permission "admin.maintenance".'.freeze

  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'import_mode')
    return if setting&.description != PREVIOUS_DESCRIPTION

    setting.update!(description: NEW_DESCRIPTION)
  end
end
