# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class OpenIdConnectPkce < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'auth_openid_connect_credentials')
    return if setting.nil?

    setting.options[:form].push({
                                  display:   'PKCE',
                                  null:      true,
                                  default:   true,
                                  name:      'pkce',
                                  tag:       'select',
                                  options:   {
                                    true  => 'yes',
                                    false => 'no',
                                  },
                                  translate: true,
                                  help:      'Proof Key for Code Exchange is currently only supporting SHA256 as code challenge method.',
                                })

    setting.options[:form].push({
                                  display:  'Your callback URL',
                                  null:     true,
                                  name:     'callback_url',
                                  tag:      'auth_provider',
                                  provider: 'auth_openid_connect',
                                })

    setting.save!
  end
end
