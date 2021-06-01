# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class UnableToEnableTimeAccounting633 < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Time Accounting',
      name:        'time_accounting',
      area:        'Web::Base',
      description: 'Enable time accounting.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'time_accounting',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.time_accounting'],
      },
      state:       false,
      frontend:    true
    )

    Setting.create_if_not_exists(
      title:       'Time Accounting Selector',
      name:        'time_accounting_selector',
      area:        'Web::Base',
      description: 'Enable time accounting for this tickets.',
      options:     {
        form: [
          {},
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.time_accounting'],
      },
      state:       {},
      frontend:    true
    )
  end
end
