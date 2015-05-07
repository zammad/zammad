require 'scheduler'
require 'setting'
class SchedulerCreate < ActiveRecord::Migration
  def up
    create_table :schedulers do |t|
      t.column :name,           :string, limit: 250,   null: false
      t.column :method,         :string, limit: 250,   null: false
      t.column :period,         :integer,                 null: true
      t.column :running,        :integer,                 null: false, default: false
      t.column :last_run,       :timestamp,               null: true
      t.column :prio,           :integer,                 null: false
      t.column :pid,            :string, limit: 250,   null: true
      t.column :note,           :string, limit: 250,   null: true
      t.column :active,         :boolean,                 null: false, default: false
      t.column :updated_by_id,  :integer,                 null: false
      t.column :created_by_id,  :integer,                 null: false
      t.timestamps
    end
    add_index :schedulers, [:name], unique: true
    Scheduler.create_or_update(
      name: 'Import OTRS diff load',
      method: 'Import::OTRS.diff_worker',
      period: 60 * 3,
      prio: 1,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Scheduler.create_or_update(
      name: 'Check Channels',
      method: 'Channel.fetch',
      period: 30,
      prio: 1,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Scheduler.create_or_update(
      name: 'Generate Session data',
      method: 'Sessions.jobs',
      period: 60,
      prio: 1,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Scheduler.create_or_update(
      name: 'Cleanup expired sessions',
      method: 'SessionHelper.cleanup_expired',
      period: 60 * 60 * 24,
      prio: 2,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  def down
    drop_table :schedulers
  end
end
