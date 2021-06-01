# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SamlAuth < ActiveRecord::Migration[5.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Authentication via %s',
      name:        'auth_saml',
      area:        'Security::ThirdPartyAuthentication',
      description: 'Enables user authentication via %s.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'auth_saml',
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
        sub:              ['auth_saml_credentials'],
        title_i18n:       ['SAML'],
        description_i18n: ['SAML'],
        permission:       ['admin.security'],
      },
      state:       false,
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'SAML App Credentials',
      name:        'auth_saml_credentials',
      area:        'Security::ThirdPartyAuthentication::SAML',
      description: 'Enables user authentication via SAML.',
      options:     {
        form: [
          {
            display:     'IDP SSO target URL',
            null:        true,
            name:        'idp_sso_target_url',
            tag:         'input',
            placeholder: 'https://capriza.github.io/samling/samling.html',
          },
          {
            display:     'IDP certificate',
            null:        true,
            name:        'idp_cert',
            tag:         'input',
            placeholder: '-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----',
          },
          {
            display:     'IDP certificate fingerprint',
            null:        true,
            name:        'idp_cert_fingerprint',
            tag:         'input',
            placeholder: 'E7:91:B2:E1:...',
          },
          {
            display:     'Name Identifier Format',
            null:        true,
            name:        'name_identifier_format',
            tag:         'input',
            placeholder: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
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
