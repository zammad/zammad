class CtiGenericApi < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Setting.create_if_not_exists(
      title: 'cti integration',
      name: 'cti_integration',
      area: 'Integration::Switch',
      description: 'Defines if generic CTI is enabled or not.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'cti_integration',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: false,
      preferences: {
        prio: 1,
        trigger: ['menu:render', 'cti:reload'],
        authentication: true,
        permission: ['admin.integration'],
      },
      frontend: true
    )
    Setting.create_if_not_exists(
      title: 'cti config',
      name: 'cti_config',
      area: 'Integration::Cti',
      description: 'Defines the cti config.',
      options: {},
      state: { 'outbound' => { 'routing_table' => [], 'default_caller_id' => '' }, 'inbound' => { 'block_caller_ids' => [] } },
      preferences: {
        prio: 2,
        permission: ['admin.integration'],
      },
      frontend: false,
    )
    Setting.create_if_not_exists(
      title: 'CTI Token',
      name: 'cti_token',
      area: 'Integration::Cti',
      description: 'Token for cti.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'cti_token',
            tag: 'input',
          },
        ],
      },
      state: SecureRandom.urlsafe_base64(20),
      preferences: {
        permission: ['admin.integration'],
      },
      frontend: false
    )

    add_column :cti_logs, :queue, :string, limit: 250, null: true
    add_column :cti_logs, :initialized_at, :string, limit: 250, null: true
    add_column :cti_logs, :duration_waiting_time, :integer, null: true
    add_column :cti_logs, :duration_talking_time, :integer, null: true

    rename_column :cti_logs, :start, :start_at
    rename_column :cti_logs, :end, :end_at

  end
end
