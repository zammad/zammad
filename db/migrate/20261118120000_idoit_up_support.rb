# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class IdoitUpSupport < ActiveRecord::Migration[8.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'i-doit up integration',
      name:        'idoit_up_integration',
      area:        'Integration::Switch',
      description: 'Defines if the i-doit up integration is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'idoit_up_integration',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        prio:           1,
        authentication: true,
        permission:     ['admin.integration'],
      },
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'i-doit up config',
      name:        'idoit_up_config',
      area:        'Integration::IdoitUp',
      description: 'Defines the i-doit up config.',
      options:     {},
      state:       {},
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    false,
    )
  end
end
