# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SettingUpdatePasswordMaxLoginFailed < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'password_max_login_failed')
    setting.preferences[:authentication] = true
    setting.frontend = true
    setting.save!
  end
end
