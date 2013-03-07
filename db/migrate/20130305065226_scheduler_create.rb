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
    add_index :schedulers, [:name], :unique => true
  end

  def down
    drop_table :schedulers
  end
end
