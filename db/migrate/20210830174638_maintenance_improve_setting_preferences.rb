# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class MaintenanceImproveSettingPreferences < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    protected_settings = %w[application_secret]

    protected_settings.each do |name|
      setting = Setting.find_by(name: name)
      setting.preferences[:protected] = true
      setting.save!
    end
  end
end
