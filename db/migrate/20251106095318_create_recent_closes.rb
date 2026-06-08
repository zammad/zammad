# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CreateRecentCloses < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :recent_closes, id: :integer do |t|
      t.references :recently_closed_object, polymorphic: true, null: false, type: :integer
      t.references :user, null: false, foreign_key: true, type: :integer

      t.timestamps limit: 3

      t.index %i[recently_closed_object_type recently_closed_object_id user_id],
              name:   'index_recent_closed_user_object',
              unique: true

      t.index :updated_at, order: { updated_at: :desc }
    end

    Scheduler.create_if_not_exists(
      name:          'Delete old recently closed entries.',
      method:        'RecentClose.cleanup',
      period:        1.day,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      last_run:      Time.current,
    )
  end
end
