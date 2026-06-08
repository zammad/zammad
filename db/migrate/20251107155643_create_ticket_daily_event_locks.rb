# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CreateTicketDailyEventLocks < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :ticket_daily_event_locks, id: :integer do |t|
      t.date :date, null: false
      t.string :lock_type, null: false
      t.string :lock_activator, null: false
      t.references :ticket, null: false, type: :integer, foreign_key: { to_table: :tickets }
      t.references :related_object, polymorphic: true, type: :integer, null: true

      t.index %i[date lock_type lock_activator ticket_id related_object_type related_object_id],
              name:   'index_daily_event_locks_on_unique_fields',
              unique: true

      t.timestamps limit: 3
    end

    Scheduler.create_if_not_exists(
      name:          "Clean up 'Ticket::DailyeventLock'.",
      method:        'Ticket::DailyEventLock.cleanup',
      period:        1.day,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      last_run:      Time.zone.now,
    )
  end
end
