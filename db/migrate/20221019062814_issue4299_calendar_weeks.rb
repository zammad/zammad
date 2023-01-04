# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4299CalendarWeeks < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Show calendar weeks in the picker of date/datetime fields',
      name:        'datepicker_show_calendar_weeks',
      area:        'System::UI',
      description: 'Defines if calendar weeks are shown in the picker of date/datetime fields to easily select the correct date.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'datepicker_show_calendar_weeks',
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
        render:     true,
        prio:       4,
        permission: ['admin.system'],
      },
      frontend:    true
    )
  end
end
