class ActiveJobLockCleanupJobScheduler < ActiveRecord::Migration[5.2]
  def up
    return if !Setting.find_by(name: 'system_init_done')

    Scheduler.create_or_update(
      name:          'Cleanup ActiveJob locks.',
      method:        'ActiveJobLockCleanupJob.perform_now',
      period:        1.day,
      last_run:      Time.zone.now,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end
