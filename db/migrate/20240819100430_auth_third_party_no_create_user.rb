# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AuthThirdPartyNoCreateUser < ActiveRecord::Migration[5.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'No user creation on logon',
      name:        'auth_third_party_no_create_user',
      area:        'Security::ThirdPartyAuthentication',
      description: 'Disables user creation on logon vwith a third-party application.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'auth_third_party_no_create_user',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        permission: ['admin.security'],
        prio:       20,
      },
      state:       false,
      frontend:    false
    )
  end
end
