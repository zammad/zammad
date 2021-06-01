# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class PrettyDateOptionsAdded < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_or_update(
      title:       'Pretty Date',
      name:        'pretty_date_format',
      area:        'System::Branding',
      description: 'Defines pretty date format.',
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'pretty_date_format',
            tag:     'select',
            options: {
              relative: 'relative - e. g. "2 hours ago" or "2 days and 15 minutes ago"',
              absolute: 'absolute - e. g. "Monday 09:30" or "Tuesday 23. Feb 14:20"',
            },
          },
        ],
      },
      preferences: {
        render:     true,
        prio:       10,
        permission: ['admin.branding'],
      },
      state:       'relative',
      frontend:    true
    )

    Scheduler.create_or_update(
      name:          'Import Jobs',
      method:        'ImportJob.start_registered',
      period:        1.hour,
      prio:          1,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1
    )
  end

end
