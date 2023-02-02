# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class AddTaskbarCleanupJob < ActiveRecord::Migration[6.1]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    Scheduler.create_if_not_exists(
      name:          'Clean up mobile taskbars.',
      method:        'TaskbarCleanupJob.perform_now',
      period:        10.minutes,
      prio:          2,
      active:        true,
      timeplan:      {
        'days'    => {
          'Mon' => true,
          'Tue' => true,
          'Wed' => true,
          'Thu' => true,
          'Fri' => true,
          'Sat' => true,
          'Sun' => true
        },
        'hours'   => {
          '1' => true
        },
        'minutes' => {
          '0' => true
        }
      },
      updated_by_id: 1,
      created_by_id: 1,
      last_run:      Time.zone.now,
    )
  end
end
