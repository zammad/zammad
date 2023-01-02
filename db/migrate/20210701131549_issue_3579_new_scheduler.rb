# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3579NewScheduler < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    Scheduler.create_if_not_exists(
      name:          'Delete old upload cache entries.',
      method:        'UploadCacheCleanupJob.perform_now',
      period:        1.month,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      last_run:      Time.zone.now,
    )
  end
end
