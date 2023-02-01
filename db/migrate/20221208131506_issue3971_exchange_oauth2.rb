# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3971ExchangeOauth2 < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Exchange OAuth',
      name:        'exchange_oauth',
      area:        'Integration::Exchange',
      description: 'Defines the Exchange OAuth config.',
      options:     {},
      state:       {},
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    false,
    )
    Scheduler.create_if_not_exists(
      name:          'Update exchange oauth 2 token.',
      method:        'ExternalCredential::Exchange.refresh_token',
      period:        10.minutes,
      prio:          1,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      last_run:      Time.zone.now,
    )
  end
end
