# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ImapAuthenticationMigrationCleanupJobScheduler < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Scheduler.create_or_update(
      name:          'Delete obsolete classic IMAP backup.',
      method:        'ImapAuthenticationMigrationCleanupJob.perform_now',
      period:        1.day,
      last_run:      Time.zone.now,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end
