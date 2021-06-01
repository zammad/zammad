# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3446Microsoft365Tenants < ActiveRecord::Migration[5.2]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by name: 'auth_microsoft_office365_credentials'
    setting.options[:form].push({
                                  display:     'App Tenant ID',
                                  null:        true,
                                  name:        'app_tenant',
                                  tag:         'input',
                                  placeholder: 'common',
                                })

    setting.save!
  end
end
