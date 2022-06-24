# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class SettingUpdates4 < ActiveRecord::Migration[6.1]
    def change
        # return if it's a new setup
      return if !Setting.exists?(name: 'system_init_done')

      Setting.create_if_not_exists(
        title:       'Enable default login',
        name:        'user_show_default_login',
        area:        'Security::Base',
        description: 'Show default login for users on login page.',
        options:     {
          form: [
            {
              display: '',
              null:    true,
              name:    'user_show_default_login',
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
          prio:       40,
          permission: ['admin.security'],
        },
        frontend:    true
      )
  end
end