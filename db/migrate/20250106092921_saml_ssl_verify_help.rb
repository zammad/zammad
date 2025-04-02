# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SamlSSLVerifyHelp < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'auth_saml_credentials')
    return if !setting

    update_needed = false

    setting.options[:form].each do |o|
      next if !o[:name].eql?('ssl_verify')

      o[:help] = 'Verification of the TLS connection to the IDP SSO target URL. Only relevant during setting up SAML authentication.'
      update_needed = true
    end

    return if !update_needed

    setting.save!(validate: false)
  end
end
