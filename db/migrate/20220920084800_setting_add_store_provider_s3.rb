# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SettingAddStoreProviderS3 < ActiveRecord::Migration[6.1]

  def change
    return if !Setting.exists?(name: 'system_init_done')

    storage_provider = Setting.find_by(name: 'storage_provider')
    storage_provider.description = '"Database" stores all attachments in the database (not recommended for storing large amounts of data). "Filesystem" stores the data in the filesystem. "Simple Storage (S3)" stores the data in a remote S3 compatible object filesystem. You can switch between the modules even on a system that is already in production without any loss of data.'
    storage_provider.options = {
      form: [
        {
          display:   '',
          null:      true,
          name:      'storage_provider',
          tag:       'select',
          options:   {
            'DB'   => 'Database',
            'File' => 'Filesystem',
            'S3'   => 'Simple Storage (S3)',
          },
          translate: true,
        },
      ],
    }
    storage_provider.save!
  end
end
