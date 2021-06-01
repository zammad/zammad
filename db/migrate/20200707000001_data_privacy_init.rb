# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class DataPrivacyInit < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    up_table
    up_permission
    up_scheduler
  end

  def up_table
    create_table :data_privacy_tasks do |t|
      t.column :name,                 :string, limit: 150,                        null: true
      t.column :state,                :string, limit: 150, default: 'in process', null: true
      t.references :deletable,        polymorphic: true
      t.string :preferences,          limit: 8000,                                null: true
      t.column :updated_by_id,        :integer,                                   null: false
      t.column :created_by_id,        :integer,                                   null: false
      t.timestamps limit: 3, null: false
    end
    add_index :data_privacy_tasks, [:name]
    add_index :data_privacy_tasks, [:state]
  end

  def up_permission
    Permission.create_if_not_exists(
      name:        'admin.data_privacy',
      note:        'Manage %s',
      preferences: {
        translations: ['Data Privacy']
      },
    )
  end

  def up_scheduler
    Scheduler.create_or_update(
      name:          'Handle data privacy tasks.',
      method:        'DataPrivacyTaskJob.perform_now',
      period:        10.minutes,
      last_run:      Time.zone.now,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  def self.down
    drop_table :data_privacy_tasks
  end
end
