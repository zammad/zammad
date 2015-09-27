class CreateJob < ActiveRecord::Migration
  def up
    create_table :jobs do |t|
      t.column :name,           :string,  limit: 250,  null: false
      t.column :timeplan,       :string,  limit: 500,  null: false
      t.column :condition,      :string,  limit: 2500, null: false
      t.column :execute,        :string,  limit: 2500, null: false
      t.column :last_run_at,    :timestamp,               null: true
      t.column :running,        :boolean,                 null: false, default: false
      t.column :processed,      :integer,                 null: false, default: 0
      t.column :matching,       :integer,                 null: false
      t.column :pid,            :string, limit: 250,   null: true
      t.column :note,           :string, limit: 250,   null: true
      t.column :active,         :boolean,                 null: false, default: false
      t.column :updated_by_id,  :integer,                 null: false
      t.column :created_by_id,  :integer,                 null: false
      t.timestamps                                        null: false
    end
    add_index :jobs, [:name], unique: true
  end

  def down
    drop_table :jobs
  end
end
