# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class RoleSignupColumnFix < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    if !column_exists?(:permissions, :allow_signup)
      add_column :permissions, :allow_signup, :boolean, null: false, default: false
    end

    Permission.reset_column_information

    signup_permissions = [
      'user_preferences',
      'user_preferences.password',
      'user_preferences.notifications',
      'user_preferences.access_token',
      'user_preferences.language',
      'user_preferences.linked_accounts',
      'user_preferences.device',
      'user_preferences.avatar',
      'user_preferences.calendar',
      'user_preferences.out_of_office',
      'ticket.customer',
    ]

    Permission.where(name: signup_permissions).update(allow_signup: true)

    Role.where(default_at_signup: true).find_each do |role|
      role.permissions.where.not(name: signup_permissions).find_each do |permission|
        role.permission_revoke(permission.name)
      end
    end
  end
end
