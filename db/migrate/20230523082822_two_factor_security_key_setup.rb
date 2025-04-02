# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TwoFactorSecurityKeySetup < ActiveRecord::Migration[6.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Security Keys',
      name:        'two_factor_authentication_method_security_keys',
      area:        'Security::TwoFactorAuthentication',
      description: 'Defines if the two-factor authentication method security keys is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'two_factor_authentication_method_security_keys',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        controller:   'SettingsAreaSwitch',
        sub:          {},
        permission:   ['admin.security'],
        prio:         1000,
        display_name: 'Security Keys',
        help:         'Complete the sign-in with your security key.',
        icon:         'security-key',
      },
      state:       false,
      frontend:    true
    )
  end
end
