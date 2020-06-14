class DiscordOauth2 < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')
    Setting.find_by(name: 'auth_discord').destroy
    Setting.find_by(name: 'auth_discord_credentials').destroy
    Setting.create_if_not_exists(
      title:       'Authentication via %s',
      name:        'auth_discord',
      area:        'Security::ThirdPartyAuthentication',
      description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'auth_discord',
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
        sub:              ['auth_discord_credentials'],
        title_i18n:       ['Discord'],
        description_i18n: ['Discord', 'Discord', 'http://discord.com'],
        permission:       ['admin.security'],
      },
      state:       false,
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'Discord App Credentials',
      name:        'auth_discord_credentials',
      area:        'Security::ThirdPartyAuthentication::Discord',
      description: 'Enables user authentication via Discord.',
      options:     {
        form: [
          {
            display: 'Client ID',
            null:    true,
            name:    'client_id',
            tag:     'input',
          },
          {
            display: 'Client Secret',
            null:    true,
            name:    'client_secret',
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