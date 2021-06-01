# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CtiGenericApi < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'cti integration',
      name:        'cti_integration',
      area:        'Integration::Switch',
      description: 'Defines if generic CTI is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'cti_integration',
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
        trigger:        ['menu:render', 'cti:reload'],
        authentication: true,
        permission:     ['admin.integration'],
      },
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'cti config',
      name:        'cti_config',
      area:        'Integration::Cti',
      description: 'Defines the cti config.',
      options:     {},
      state:       { 'outbound' => { 'routing_table' => [], 'default_caller_id' => '' }, 'inbound' => { 'block_caller_ids' => [] } },
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    false,
    )
    Setting.create_if_not_exists(
      title:       'CTI Token',
      name:        'cti_token',
      area:        'Integration::Cti',
      description: 'Token for cti.',
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'cti_token',
            tag:     'input',
          },
        ],
      },
      state:       SecureRandom.urlsafe_base64(20),
      preferences: {
        permission: ['admin.integration'],
      },
      frontend:    false
    )

    add_column :cti_logs, :queue, :string, limit: 250, null: true          if !column_exists?(:cti_logs, :queue)
    add_column :cti_logs, :initialized_at, :string, limit: 250, null: true if !column_exists?(:cti_logs, :initialized_at)
    add_column :cti_logs, :duration_waiting_time, :integer, null: true     if !column_exists?(:cti_logs, :duration_waiting_time)
    add_column :cti_logs, :duration_talking_time, :integer, null: true     if !column_exists?(:cti_logs, :duration_talking_time)

    # fixes issue #2183 - Mysql2::Error: Invalid default value for 'start_at'
    if ActiveRecord::Base.connection_config[:adapter] == 'mysql2'
      # disable the MySQL strict_mode for the current connection
      execute("SET sql_mode = ''")

      change_column_default :cti_logs, :start, '0000-00-00 00:00:00'
      change_column_default :cti_logs, :end, '0000-00-00 00:00:00'
    end

    rename_column :cti_logs, :start, :start_at
    rename_column :cti_logs, :end, :end_at

  end
end
