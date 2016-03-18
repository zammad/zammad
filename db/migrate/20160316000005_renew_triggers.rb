class RenewTriggers < ActiveRecord::Migration
  def up
    drop_table :triggers
    create_table :triggers do |t|
      t.column :name,                 :string, limit: 250,  null: false
      t.column :condition,            :string, limit: 2500, null: false
      t.column :perform,              :string, limit: 2500, null: false
      t.column :disable_notification, :boolean,             null: false, default: true
      t.column :note,                 :string, limit: 250,  null: true
      t.column :active,               :boolean,             null: false, default: true
      t.column :updated_by_id,        :integer,             null: false
      t.column :created_by_id,        :integer,             null: false
      t.timestamps                                          null: false
    end
    add_index :triggers, [:name], unique: true

    drop_table :jobs
    create_table :jobs do |t|
      t.column :name,                 :string,  limit: 250,  null: false
      t.column :timeplan,             :string,  limit: 1000, null: false
      t.column :condition,            :string,  limit: 2500, null: false
      t.column :perform,              :string,  limit: 2500, null: false
      t.column :disable_notification, :boolean,              null: false, default: true
      t.column :last_run_at,          :timestamp,            null: true
      t.column :running,              :boolean,              null: false, default: false
      t.column :processed,            :integer,              null: false, default: 0
      t.column :matching,             :integer,              null: false, default: 0
      t.column :pid,                  :string, limit: 250,   null: true
      t.column :note,                 :string, limit: 250,   null: true
      t.column :active,               :boolean,              null: false, default: false
      t.column :updated_by_id,        :integer,              null: false
      t.column :created_by_id,        :integer,              null: false
      t.timestamps null: false
    end
    add_index :jobs, [:name], unique: true

    Scheduler.create_if_not_exists(
      name: 'Execute jobs',
      method: 'Job.run',
      period: 5 * 60,
      prio: 2,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

  end
end
