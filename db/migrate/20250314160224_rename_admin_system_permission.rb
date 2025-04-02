# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class RenameAdminSystemPermission < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    admin_system_permission = Permission.find_by(name: 'admin.setting_system')
    return if admin_system_permission.blank?

    admin_system_permission.update!(name: 'admin.system')
  end
end
