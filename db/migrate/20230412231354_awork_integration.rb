class AworkIntegration < ActiveRecord::Migration[6.1]
  def up

    change_column :http_logs, :response, :mediumtext

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Awork integration',
      name:        'awork_integration',
      area:        'Integration::Switch',
      description: 'Defines if the Awork (https://www.awork.io/) integration is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'awork_integration',
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
      title:       'Awork config',
      name:        'awork_config',
      area:        'Integration::Awork',
      description: 'Stores the Awork configuration.',
      options:     {},
      state:       {
        endpoint: 'https://api.awork.io/api/v1',
      },
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    false,
    )
  end
end