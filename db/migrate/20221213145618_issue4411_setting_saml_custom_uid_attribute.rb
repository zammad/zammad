# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4411SettingSamlCustomUidAttribute < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    saml_setting = Setting.find_by(name: 'auth_saml_credentials')
    return if !saml_setting

    saml_setting.options[:form].insert(-2, {
                                         display:     'UID Attribute Name',
                                         null:        true,
                                         name:        'uid_attribute',
                                         tag:         'input',
                                         placeholder: '',
                                         help:        'Attribute that uniquely identifies the user. If unset, the name identifier returned by the IDP is used.',
                                       })

    saml_setting.save!
  end
end
