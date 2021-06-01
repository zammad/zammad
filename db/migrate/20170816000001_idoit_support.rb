# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class IdoitSupport < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'i-doit integration',
      name:        'idoit_integration',
      area:        'Integration::Switch',
      description: 'Defines if i-doit (http://www.i-doit) is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'idoit_integration',
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
      title:       'i-doit config',
      name:        'idoit_config',
      area:        'Integration::Idoit',
      description: 'Defines the i-doit config.',
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
