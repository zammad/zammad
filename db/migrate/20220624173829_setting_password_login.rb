# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SettingPasswordLogin < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Password Login',
      name:        'user_show_password_login',
      area:        'Security::Base',
      description: 'Show password login for users on login page. Disabling only takes effect if third-party authentication is enabled.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'user_show_password_login',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       true,
      preferences: {
        prio:       25,
        permission: ['admin.security'],
      },
      frontend:    true
    )
  end
end
