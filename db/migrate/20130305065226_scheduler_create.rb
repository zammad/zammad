class SchedulerCreate < ActiveRecord::Migration
  def up
    create_table :schedulers do |t|
      t.column :name,           :string, :limit => 250,   :null => false
      t.column :method,         :string, :limit => 250,   :null => false
      t.column :period,         :integer,                 :null => true
      t.column :running,        :integer,                 :null => false, :default => false
      t.column :last_run,       :timestamp,               :null => true
      t.column :pid,            :string, :limit => 250,   :null => true
      t.column :note,           :string, :limit => 250,   :null => true
      t.column :active,         :boolean,                 :null => false, :default => false
      t.column :updated_by_id,  :integer,                 :null => false
      t.column :created_by_id,  :integer,                 :null => false
      t.timestamps
    end
    Scheduler.create(
      :name           => 'Check Channels',
      :method         => 'Channel.fetch',
      :period         => 30,
      :active         => true,
      :updated_by_id  => 1,
      :created_by_id  => 1,
    )
    Scheduler.create(
      :name           => 'Import OTRS diff load',
      :method         => 'Import::OTRS.diff_loop',
      :period         => 60 * 10,
      :active         => true,
      :updated_by_id  => 1,
      :created_by_id  => 1,
    )
    Scheduler.create(
      :name           => 'Generate Session data',
      :method         => 'Session.jobs',
      :period         => 60,
      :active         => true,
      :updated_by_id  => 1,
      :created_by_id  => 1,
    )
    add_index :schedulers, [:name], :unique => true
  end

  def down
    drop_table :schedulers
  end
end
