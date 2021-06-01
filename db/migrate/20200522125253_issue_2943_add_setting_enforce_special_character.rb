# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue2943AddSettingEnforceSpecialCharacter < ActiveRecord::Migration[5.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Special character required',
      name:        'password_need_special_character',
      area:        'Security::Password',
      description: 'Password needs to contain at least one special character.',
      options:     {
        form: [
          {
            display: 'Needed',
            null:    true,
            name:    'password_need_special_character',
            tag:     'select',
            options: {
              1 => 'yes',
              0 => 'no',
            },
          },
        ],
      },
      state:       0,
      preferences: {
        permission: ['admin.security'],
      },
      frontend:    false
    )
  end
end
