# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CheckMkIntegration2 < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Check_MK integration',
      name:        'check_mk_integration',
      area:        'Integration::Switch',
      description: 'Defines if Check_MK (http://mathias-kettner.com/check_mk.html) is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'check_mk_integration',
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
      name:        'check_mk_sender',
      area:        'Integration::CheckMK',
      description: 'Defines the sender email address of the service emails.',
      options:     {
        form: [
          {
            display:     '',
            null:        false,
            name:        'check_mk_sender',
            tag:         'input',
            placeholder: 'check_mk@monitoring.example.com',
          },
        ],
      },
      state:       'check_mk@monitoring.example.com',
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    false,
    )
    Setting.create_if_not_exists(
      title:       'Group',
      name:        'check_mk_group_id',
      area:        'Integration::CheckMK',
      description: 'Defines the group of created tickets.',
      options:     {
        form: [
          {
            display:  '',
            null:     false,
            name:     'check_mk_group_id',
            tag:      'select',
            relation: 'Group',
          },
        ],
      },
      state:       1,
      preferences: {
        prio:       3,
        permission: ['admin.integration'],
      },
      frontend:    false
    )
    Setting.create_if_not_exists(
      title:       'Auto close',
      name:        'check_mk_auto_close',
      area:        'Integration::CheckMK',
      description: 'Defines if tickets should be closed if service is recovered.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'check_mk_auto_close',
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
        prio:       4,
        permission: ['admin.integration'],
      },
      frontend:    false
    )
    Setting.create_if_not_exists(
      title:       'Auto close state',
      name:        'check_mk_auto_close_state_id',
      area:        'Integration::CheckMK',
      description: 'Defines the state of auto closed tickets.',
      options:     {
        form: [
          {
            display:   '',
            null:      false,
            name:      'check_mk_auto_close_state_id',
            tag:       'select',
            relation:  'TicketState',
            translate: true,
          },
        ],
      },
      state:       4,
      preferences: {
        prio:       5,
        permission: ['admin.integration'],
      },
      frontend:    false
    )
    Setting.create_if_not_exists(
      title:       'Check_MK tolen',
      name:        'check_mk_token',
      area:        'Core',
      description: 'Defines the Check_MK token for allowing updates.',
      options:     {},
      state:       SecureRandom.hex(16),
      preferences: {
        permission: ['admin.integration'],
      },
      frontend:    false
    )
    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '5200_postmaster_filter_check_mk',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to manage Check_MK (http://mathias-kettner.com/check_mk.html) emails.',
      options:     {},
      state:       'Channel::Filter::CheckMk',
      frontend:    false
    )
  end

end
