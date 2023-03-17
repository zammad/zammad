# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4263SamlDisplayName < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    saml_setting = Setting.find_by(name: 'auth_saml_credentials')
    return if !saml_setting

    saml_setting.options[:form].unshift({
                                          display:     'Display name',
                                          null:        true,
                                          name:        'display_name',
                                          tag:         'input',
                                          placeholder: 'SAML',
                                        })

    saml_setting.save!
  end
end
