# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class OpenIdConnectManualSettings < ActiveRecord::Migration[7.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'auth_openid_connect_credentials')
    return if setting.nil?

    setting.options[:form].insert(3, {
                                    display:   'Discovery',
                                    null:      true,
                                    default:   true,
                                    name:      'discovery',
                                    tag:       'select',
                                    options:   {
                                      true  => 'yes',
                                      false => 'no',
                                    },
                                    translate: true,
                                    help:      'When activated, the issuer URL is used to discover the endpoints and keys. This option requires HTTPS (self-signed certificates are not supported).',
                                  },
                                  {
                                    display:     'Secret',
                                    null:        true,
                                    name:        'secret',
                                    tag:         'input',
                                    required:    false,
                                    placeholder: '',
                                    translate:   true,
                                    help:        'This option is only required if discovery is disabled.',
                                  },
                                  {
                                    display:     'Authorization endpoint',
                                    null:        true,
                                    name:        'authorization_endpoint',
                                    tag:         'input',
                                    placeholder: '/authorize',
                                    required:    false,
                                    translate:   true,
                                    help:        'This option is only required if discovery is disabled.',
                                  },
                                  {
                                    display:     'Token endpoint',
                                    null:        true,
                                    name:        'token_endpoint',
                                    tag:         'input',
                                    placeholder: '/token',
                                    required:    false,
                                    translate:   true,
                                    help:        'This option is only required if discovery is disabled.',
                                  },
                                  {
                                    display:     'Userinfo endpoint',
                                    null:        true,
                                    name:        'userinfo_endpoint',
                                    tag:         'input',
                                    placeholder: '/userinfo',
                                    required:    false,
                                    translate:   true,
                                    help:        'This option is only required if discovery is disabled.',
                                  },
                                  {
                                    display:     'JWKS uri',
                                    null:        true,
                                    name:        'jwks_uri',
                                    tag:         'input',
                                    placeholder: 'https://example.com/jwks',
                                    required:    false,
                                    translate:   true,
                                    help:        'This option is only required if discovery is disabled. As opposed to other endpoints, this one must include the full URL of the OIDC JSON web key (JWK) endpoint and not just the path.',
                                  })

    setting.save!
  end
end
