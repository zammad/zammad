# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Add2faPermission < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_permission
    modify_roles
  end

  private

  def add_permission
    Permission.create_if_not_exists(
      name:         'user_preferences.two_factor_authentication',
      note:         'Change %s',
      preferences:  {
        translations: ['Two-factor Authentication']
      },
      allow_signup: true,
    )
  end

  def modify_roles
    Role
      .joins(:permissions)
      .where(permissions: { name: 'user_preferences.password' })
      .each do |role|
        role.permission_grant('user_preferences.two_factor_authentication')
      end
  end
end
