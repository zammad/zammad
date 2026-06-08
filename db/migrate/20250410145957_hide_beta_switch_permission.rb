# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HideBetaSwitchPermission < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    permission = Permission.find_by(name: 'user_preferences.beta_ui_switch')
    permission.preferences[:setting] = {
      name:  'ui_desktop_beta_switch',
      value: true,
    }
    permission.save!
  end
end
