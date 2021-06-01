# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class OmniauthOffice365Setting < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Authentication via %s',
      name:        'auth_microsoft_office365',
      area:        'Security::ThirdPartyAuthentication',
      description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'auth_microsoft_office365',
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
        sub:              ['auth_microsoft_office365_credentials'],
        title_i18n:       ['Office 365'],
        description_i18n: ['Office 365', 'Microsoft Application Registration Portal', 'https://apps.dev.microsoft.com'],
        permission:       ['admin.security'],
      },
      state:       false,
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'Office 365 App Credentials',
      name:        'auth_microsoft_office365_credentials',
      area:        'Security::ThirdPartyAuthentication::Office365',
      description: 'Enables user authentication via Office 365.',
      options:     {
        form: [
          {
            display: 'App ID',
            null:    true,
            name:    'app_id',
            tag:     'input',
          },
          {
            display: 'App Secret',
            null:    true,
            name:    'app_secret',
            tag:     'input',
          },
        ],
      },
      state:       {},
      preferences: {
        permission: ['admin.security'],
      },
      frontend:    false
    )
  end
end
