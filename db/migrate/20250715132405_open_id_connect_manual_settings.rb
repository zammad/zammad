class OpenIdConnectManualSettings < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'auth_openid_connect_credentials')
    return if setting.nil?

    setting.options[:form].insert(3, {
                                    display:   __('Discovery'),
                                    null:      true,
                                    default:   true,
                                    name:      'discovery',
                                    tag:       'select',
                                    options:   {
                                      true  => 'yes',
                                      false => 'no',
                                    },
                                    translate: true,
                                    help:      __('When activated, the issuer URL is used to discover the endpoints and keys. This option requires HTTPS (self-signed certificates are not supported).'),
                                  },
                                  {
                                    display:     __('Secret'),
                                    null:        true,
                                    name:        'secret',
                                    tag:         'input',
                                    required:    false,
                                    placeholder: '',
                                    translate:   true,
                                    help:        __('This option is only required if discovery is disabled.'),
                                  },
                                  {
                                    display:     __('Authorization endpoint'),
                                    null:        true,
                                    name:        'authorization_endpoint',
                                    tag:         'input',
                                    placeholder: __('/authorize'),
                                    required:    false,
                                    translate:   true,
                                    help:        __('This option is only required if discovery is disabled.'),
                                  },
                                  {
                                    display:     __('Token endpoint'),
                                    null:        true,
                                    name:        'token_endpoint',
                                    tag:         'input',
                                    placeholder: __('/token'),
                                    required:    false,
                                    translate:   true,
                                    help:        __('This option is only required if discovery is disabled.'),
                                  },
                                  {
                                    display:     __('Userinfo endpoint'),
                                    null:        true,
                                    name:        'userinfo_endpoint',
                                    tag:         'input',
                                    placeholder: __('/userinfo'),
                                    required:    false,
                                    translate:   true,
                                    help:        __('This option is only required if discovery is disabled.'),
                                  },
                                  {
                                    display:     __('JWKS uri'),
                                    null:        true,
                                    name:        'jwks_uri',
                                    tag:         'input',
                                    placeholder: __('https://example.com/jwks'),
                                    required:    false,
                                    translate:   true,
                                    help:        __('This option is only required if discovery is disabled. As opposed to other endpoints, this one must include the full URL of the OIDC JSON web key (JWK) endpoint and not just the path.'),
                                  })

    setting.save!
  end
end
