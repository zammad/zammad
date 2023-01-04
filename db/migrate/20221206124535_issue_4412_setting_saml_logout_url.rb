# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4412SettingSamlLogoutUrl < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    saml_setting = Setting.find_by(name: 'auth_saml_credentials')
    return if !saml_setting

    saml_setting.options[:form].insert(2, {
                                         display:     'IDP Single Logout target URL',
                                         null:        true,
                                         name:        'idp_slo_service_url',
                                         tag:         'input',
                                         placeholder: 'https://capriza.github.io/samling/slo.html',
                                       })

    saml_setting.save!
  end
end
