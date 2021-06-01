# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class MonitoringIssue453 < ActiveRecord::Migration[4.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Monitoring Token',
      name:        'monitoring_token',
      area:        'HealthCheck::Base',
      description: 'Token for Monitoring.',
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'monitoring_token',
            tag:     'input',
          },
        ],
      },
      state:       SecureRandom.urlsafe_base64(40),
      preferences: {
        permission: ['admin.monitoring'],
      },
      frontend:    false,
    )

    Permission.create_if_not_exists(
      name:        'admin.monitoring',
      note:        'Manage %s',
      preferences: {
        translations: ['Monitoring']
      },
    )

  end
end
