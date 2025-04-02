# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ChangeTokenExpirationHandling < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    migrate_table_column
    migrate_scheduler_job
  end

  def migrate_table_column
    change_table :tokens do |t|
      t.change :expires_at, :datetime, null: true, limit: 3
    end

    Token.reset_column_information

    Token.where.not(expires_at: nil).in_batches.each_record do |token|
      date = token.expires_at.to_date
      time = Time.use_zone(Setting.get('timezone_default')) { date.beginning_of_day }

      token.update! expires_at: time
    end
  end

  def migrate_scheduler_job
    Scheduler.create_or_update(
      name:          'Delete old token entries.',
      method:        'Token.cleanup',
      period:        1.day,
      prio:          2,
      active:        true,
      last_run:      Time.zone.now,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end
