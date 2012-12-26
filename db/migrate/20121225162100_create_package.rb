class CreatePackage < ActiveRecord::Migration
  def up
    create_table :packages do |t|
      t.column :name,                 :string, :limit => 250,   :null => false
      t.column :version,              :string, :limit => 50,    :null => false
      t.column :vendor,               :string, :limit => 150,   :null => false
      t.column :state,                :string, :limit => 50,    :null => false
      t.column :updated_by_id,        :integer,                 :null => false
      t.column :created_by_id,        :integer,                 :null => false
      t.timestamps
    end
    create_table :package_migrations do |t|
      t.column :name,                 :string, :limit => 250,   :null => false
      t.column :version,              :string, :limit => 250,   :null => false
      t.timestamps
    end
  end

  def down
    drop_table :packages
    drop_table :package_migrations
  end
end
