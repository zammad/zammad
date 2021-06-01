# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class MonitIntegration < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Monit integration',
      name:        'monit_integration',
      area:        'Integration::Switch',
      description: 'Defines if Monit (https://mmonit.com/monit/) is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'monit_integration',
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
        prio:       1,
        permission: ['admin.integration'],
      },
      frontend:    false
    )
    Setting.create_if_not_exists(
      title:       'Sender',
      name:        'monit_sender',
      area:        'Integration::Monit',
      description: 'Defines the sender email address of the service emails.',
      options:     {
        form: [
          {
            display:     '',
            null:        false,
            name:        'monit_sender',
            tag:         'input',
            placeholder: 'monit@monitoring.example.com',
          },
        ],
      },
      state:       'monit@monitoring.example.com',
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    false,
    )
    Setting.create_if_not_exists(
      title:       'Auto close',
      name:        'monit_auto_close',
      area:        'Integration::Monit',
      description: 'Defines if tickets should be closed if service is recovered.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'monit_auto_close',
            tag:       'boolean',
            options:   {
              true  => 'yes',
              false => 'no',
            },
            translate: true,
          },
        ],
      },
      state:       true,
      preferences: {
        prio:       3,
        permission: ['admin.integration'],
      },
      frontend:    false
    )
    Setting.create_if_not_exists(
      title:       'Auto close state',
      name:        'monit_auto_close_state_id',
      area:        'Integration::Monit',
      description: 'Defines the state of auto closed tickets.',
      options:     {
        form: [
          {
            display:   '',
            null:      false,
            name:      'monit_auto_close_state_id',
            tag:       'select',
            relation:  'TicketState',
            translate: true,
          },
        ],
      },
      state:       4,
      preferences: {
        prio:       4,
        permission: ['admin.integration'],
      },
      frontend:    false
    )
    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '5300_postmaster_filter_monit',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to manage Monit (https://mmonit.com/monit/) emails.',
      options:     {},
      state:       'Channel::Filter::Monit',
      frontend:    false
    )
  end

end
