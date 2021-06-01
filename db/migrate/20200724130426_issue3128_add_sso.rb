# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3128AddSso < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Authentication via %s',
      name:        'auth_sso',
      area:        'Security::ThirdPartyAuthentication',
      description: 'Enables button for user authentication via %s. The button will redirect to /auth/sso on user interaction.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'auth_sso',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        controller:       'SettingsAreaSwitch',
        sub:              {},
        title_i18n:       ['SSO'],
        description_i18n: ['SSO', 'Button for Single Sign On.'],
        permission:       ['admin.security'],
      },
      state:       false,
      frontend:    true
    )

  end
end
