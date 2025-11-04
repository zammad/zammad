# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class MaintenanceLoginMessageTransform < ActiveRecord::Migration[7.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'maintenance_login_message')
    setting.preferences[:transformations] = ['Setting::Transformation::SanitizeHtml']
    setting.save!
  end
end
