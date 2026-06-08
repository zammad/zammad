# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddSsoTrustedIpsSetting < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Trusted SSO Proxy IPs',
      name:        'auth_sso_trusted_ips',
      area:        'Security::ThirdPartyAuthentication::SSO',
      description: 'Comma-separated list of trusted proxy IP addresses or CIDR ranges for SSO header acceptance.',
      options:     {
        form: [
          {
            display:     'Trusted SSO Proxy IPs',
            null:        true,
            name:        'auth_sso_trusted_ips',
            tag:         'input',
            placeholder: '192.168.1.1, 10.0.0.0/8',
          },
        ],
      },
      preferences: {
        permission:  ['admin.security'],
        validations: ['Setting::Validation::SsoTrustedIps'],
      },
      state:       '',
      frontend:    false
    )

    setting = Setting.find_by(name: 'auth_sso')
    return if setting.nil?

    setting.description = 'Enables button for user authentication via %s. The button will redirect to /auth/sso on user interaction. Configure trusted proxy IP addresses or CIDR ranges from which authentication headers (%s, %s, %s) are accepted. Leave empty to accept from any IP (not recommended for production).'
    setting.preferences[:description_i18n] = %w[SSO REMOTE_USER HTTP_REMOTE_USER X-Forwarded-User]
    setting.preferences[:sub]              = ['auth_sso_trusted_ips']
    setting.save!
  end
end
