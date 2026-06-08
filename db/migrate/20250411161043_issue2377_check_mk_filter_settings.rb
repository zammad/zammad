# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue2377CheckMkFilterSettings < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '5200_postmaster_filter_check_mk',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to manage Checkmk (http://mathias-kettner.com/check_mk.html) emails.',
      options:     {},
      state:       'Channel::Filter::CheckMk',
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
  end
end
