# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class StoreConfigNameUpdateIssue428 < ActiveRecord::Migration[4.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'storage')
    return if !setting

    setting.name = 'storage_provider'
    setting.options = {
      form: [
        {
          display:  '',
          null:     true,
          name:     'storage_provider',
          tag:      'select',
          tranlate: true,
          options:  {
            'DB'   => 'Database',
            'File' => 'Filesystem',
          },
        },
      ],
    }
    setting.preferences = {
      controller:             'SettingsAreaStorageProvider',
      online_service_disable: true,
      permission:             ['admin.system'],
    }
    setting.save!
  end
end
