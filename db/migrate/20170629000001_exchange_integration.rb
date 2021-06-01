# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ExchangeIntegration < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.set('import_backends', ['Import::Ldap', 'Import::Exchange'])

    Setting.create_if_not_exists(
      title:       'Exchange config',
      name:        'exchange_config',
      area:        'Integration::Exchange',
      description: 'Defines the Exchange config.',
      options:     {},
      state:       {},
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    false,
    )
    Setting.create_if_not_exists(
      title:       'Exchange integration',
      name:        'exchange_integration',
      area:        'Integration::Switch',
      description: 'Defines if Exchange is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'exchange_integration',
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
  end

end
