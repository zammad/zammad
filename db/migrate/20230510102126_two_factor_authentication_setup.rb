# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TwoFactorAuthenticationSetup < ActiveRecord::Migration[6.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_two_factor_preference_table
    create_two_factor_settings
  end

  def create_two_factor_preference_table
    create_table :user_two_factor_preferences do |t|
      t.string  :method,        limit: 100,               null: false
      t.text    :configuration, limit: 500.kilobytes + 1, null: true
      t.integer :user_id,                                 null: false
      t.integer :updated_by_id,                           null: false
      t.integer :created_by_id,                           null: false
      t.timestamps limit: 3, null: false
    end
    add_index       :user_two_factor_preferences, %i[method user_id], unique: true
    add_foreign_key :user_two_factor_preferences, :users, column: :user_id
    add_foreign_key :user_two_factor_preferences, :users, column: :created_by_id
    add_foreign_key :user_two_factor_preferences, :users, column: :updated_by_id
  end

  def create_two_factor_settings
    Setting.create_if_not_exists(
      title:       'Authenticator App',
      name:        'two_factor_authentication_method_authenticator_app',
      area:        'Security::TwoFactorAuthentication',
      description: 'Defines if the two-factor authentication method authenticator app is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'two_factor_authentication_method_authenticator_app',
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
        prio:         2000,
        display_name: 'Authenticator App',
        help:         'Get the security code from the authenticator app on your device.',
        icon:         'mobile-code',
      },
      state:       false,
      frontend:    true
    )

    Setting.create_if_not_exists(
      title:       'Enforce the set up of the two-factor authentication',
      name:        'two_factor_authentication_enforce_role_ids',
      area:        'Security::TwoFactorAuthentication',
      description: 'Requires the set up of the two-factor authentication for certain user roles.',
      options:     {
        form: [
          {
            display:   'Enforced for user roles',
            null:      true,
            name:      'two_factor_authentication_enforce_role_ids',
            tag:       'column_select',
            relation:  'Role',
            translate: true,
          },
        ],
      },
      preferences: {
        permission: ['admin.security'],
        prio:       6000,
      },
      state:       [2],
      frontend:    true
    )
  end
end
