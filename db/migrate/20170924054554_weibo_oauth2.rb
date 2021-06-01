# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class WeiboOauth2 < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Authentication via %s',
      name:        'auth_weibo',
      area:        'Security::ThirdPartyAuthentication',
      description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'auth_weibo',
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
        sub:              ['auth_weibo_credentials'],
        title_i18n:       ['Weibo'],
        description_i18n: ['Weibo', 'Sina Weibo Open Portal', 'http://open.weibo.com'],
        permission:       ['admin.security'],
      },
      state:       false,
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'Weibo App Credentials',
      name:        'auth_weibo_credentials',
      area:        'Security::ThirdPartyAuthentication::Weibo',
      description: 'Enables user authentication via Sina Weibo.',
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
