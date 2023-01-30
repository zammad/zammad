# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4437AddCleanup < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Scheduler.create_if_not_exists(
      name:          "Clean up 'DataPrivacyTask'.",
      method:        'DataPrivacyTask.cleanup',
      period:        1.day,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      last_run:      Time.zone.now,
    )
  end
end
