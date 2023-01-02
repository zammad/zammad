# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class MaintenanceImproveSipgateIntegrationHandling < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'sipgate.io Token',
      name:        'sipgate_token',
      area:        'Integration::Sipgate',
      description: 'Token for Sipgate.',
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'sipgate_token',
            tag:     'input',
          },
        ],
      },
      state:       ENV['SIPGATE_TOKEN'] || SecureRandom.urlsafe_base64(20),
      preferences: {
        permission: ['admin.integration'],
      },
      frontend:    false
    )
  end
end
