# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddAlternativeFqdnSetting < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Alternative fully qualified domain name',
      name:        'alternative_fqdn',
      area:        'System::WebSocket',
      description: 'Defines an additional fully qualified domain name of the system, which is accepted as an origin for WebSocket connections.',
      state:       '',
      preferences: {
        online_service_disable: true,
        permission:             ['admin.system'],
      },
      frontend:    false
    )
  end
end
