# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddThirdPartyLoginAutoRedirectSetting < ActiveRecord::Migration[8.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Automatic Third-party Login',
      name:        'third_party_login_auto_redirect',
      area:        'Security::Base',
      description: 'Redirect users from the login page directly to the third-party sign-in. Takes effect only if password login is disabled and exactly one third-party authentication is enabled.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'third_party_login_auto_redirect',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        prio:       6,
        permission: ['admin.security'],
      },
      frontend:    true
    )
  end
end
