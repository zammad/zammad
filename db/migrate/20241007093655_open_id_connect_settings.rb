# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class OpenIdConnectSettings < ActiveRecord::Migration[7.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Authentication via %s',
      name:        'auth_openid_connect',
      area:        'Security::ThirdPartyAuthentication',
      description: 'Enables user authentication via %s.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'auth_openid_connect',
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
        sub:              ['auth_openid_connect_credentials'],
        title_i18n:       ['OpenID Connect'],
        description_i18n: ['OpenID Connect'],
        permission:       ['admin.security'],
      },
      state:       false,
      frontend:    true
    )

    Setting.create_if_not_exists(
      title:       'OpenID Connect Options',
      name:        'auth_openid_connect_credentials',
      area:        'Security::ThirdPartyAuthentication::OIDC',
      description: 'Enables user authentication via OpenID Connect.',
      options:     {
        form: [
          {
            display:     'Display name',
            null:        true,
            name:        'display_name',
            tag:         'input',
            placeholder: 'OpenID Connect',
          },
          {
            display:     'Identifier',
            null:        true,
            name:        'identifier',
            tag:         'input',
            required:    true,
            placeholder: '',
          },
          {
            display:     'Issuer',
            null:        true,
            name:        'issuer',
            tag:         'input',
            placeholder: 'https://example.com',
            required:    true,
          },
          {
            display:     'UID Field',
            null:        true,
            name:        'uid_field',
            tag:         'input',
            placeholder: 'sub',
            help:        'Field that uniquely identifies the user. If unset, "sub" is used.'
          },
          {
            display:     'Scopes',
            null:        true,
            name:        'scope',
            tag:         'input',
            placeholder: 'openid email profile',
            help:        'Scopes that are included, separated by a single space character. If unset, "openid email profile" is used.'
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
