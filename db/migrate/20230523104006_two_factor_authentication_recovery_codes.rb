# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TwoFactorAuthenticationRecoveryCodes < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Enable Recovery Codes',
      name:        'two_factor_authentication_recovery_codes',
      area:        'Security::TwoFactorAuthentication',
      description: 'Defines if recovery codes can be used by the user when losing access to their device and cannot receive two-factor authentication codes.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'two_factor_authentication_recovery_codes',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        prio:       5000,
        permission: ['admin.security'],
      },
      state:       true,
      frontend:    true
    )
  end
end
