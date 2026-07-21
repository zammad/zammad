# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :audit_logs, id: :integer do |t|
      t.references :user, null: true, type: :integer
      t.string :user_fullname, limit: 255, null: true
      t.string :action_type, limit: 100, null: false
      t.references :auditable, polymorphic: true, null: false, type: :integer
      t.string :auditable_name, limit: 255, null: true
      t.jsonb :value_from, null: false, default: {}
      t.jsonb :value_to, null: false, default: {}
      t.string :source_ip, limit: 50, null: true
      t.jsonb :preferences, null: false, default: {}

      t.timestamps limit: 3, null: false

      t.index :action_type
      t.index :created_at
    end

    Permission.create_if_not_exists(
      name:        'admin.audit_log',
      label:       'Audit Logs',
      description: 'Manage audit logs of your system.',
      preferences: { prio: 1455 }
    )

    Scheduler.create_if_not_exists(
      name:          "Clean up 'AuditLog'.",
      method:        'AuditLog.cleanup',
      period:        1.day,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      last_run:      Time.zone.now,
    )
  end
end
