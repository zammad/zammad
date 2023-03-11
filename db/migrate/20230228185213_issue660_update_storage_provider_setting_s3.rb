# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue660UpdateStorageProviderSettingS3 < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    storage_provider = Setting.find_by(name: 'storage_provider')
    storage_provider.description = '"Database" stores all attachments in the database (not recommended for storing large amounts of data). "Filesystem" stores the data in the filesystem. "S3" stores the data in a AWS S3 compatible service. You can switch between the modules even on a system that is already in production without any loss of data.'
    storage_provider.options = {
      form: [
        {
          display:   '',
          null:      true,
          name:      'storage_provider',
          tag:       'select',
          tranlate:  true,
          options:   {
            'DB'   => 'Database',
            'File' => 'Filesystem',
            'S3'   => 'S3',
          },
          translate: true,
        },
      ]
    }
    storage_provider.preferences = {
      controller:             'SettingsAreaStorageProvider',
      prio:                   1,
      online_service_disable: true,
      permission:             ['admin.system'],
    }
    storage_provider.save!

    Setting.create_if_not_exists(
      title:       'Storage S3 access key',
      name:        'storage_provider_s3_access_key',
      area:        'System::Storage',
      description: 'S3 access key',
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'storage_provider_s3_access_key',
            tag:     'input',
          },
        ],
      },
      state:       '',
      preferences: {
        online_service_disable: true,
        prio:                   2,
        permission:             ['admin.system'],
      },
      frontend:    false
    )

    Setting.create_if_not_exists(
      title:       'Storage S3 secret key',
      name:        'storage_provider_s3_secret_key',
      area:        'System::Storage',
      description: 'S3 secret access key',
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'storage_provider_s3_secret_key',
            tag:     'input',
          },
        ],
      },
      state:       '',
      preferences: {
        online_service_disable: true,
        prio:                   3,
        permission:             ['admin.system'],
      },
      frontend:    false
    )

    Setting.create_if_not_exists(
      title:       'Storage S3 region',
      name:        'storage_provider_s3_region',
      area:        'System::Storage',
      description: 'S3 region name',
      options:     {
        form: [
          {
            display:     '',
            null:        false,
            name:        'storage_provider_s3_region',
            tag:         'input',
            placeholder: 'us-west-2',
          },
        ],
      },
      state:       '',
      preferences: {
        online_service_disable: true,
        prio:                   4,
        permission:             ['admin.system'],
      },
      frontend:    false
    )
  end
end
