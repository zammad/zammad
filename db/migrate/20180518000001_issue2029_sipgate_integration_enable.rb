# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue2029SipgateIntegrationEnable < ActiveRecord::Migration[5.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    return if Setting.get('sipgate_config').present?

    Setting.create_or_update(
      title:       'sipgate.io config',
      name:        'sipgate_config',
      area:        'Integration::Sipgate',
      description: 'Defines the sipgate.io config.',
      options:     {},
      state:       { 'outbound' => { 'routing_table' => [], 'default_caller_id' => '' }, 'inbound' => { 'block_caller_ids' => [] } },
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    false,
    )

  end
end
