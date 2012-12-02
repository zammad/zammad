class CreateStorage < ActiveRecord::Migration
  def up
    create_table :stores do |t|
      t.references :store_object,               :null => false
      t.references :store_file,                 :null => false
      t.column :o_id,           :integer,       :limit => 8,    :null => false
      t.column :preferences,    :string,        :limit => 2500, :null => true
      t.column :size,           :string,        :limit => 50,   :null => true
      t.column :filename,       :string,        :limit => 250,  :null => false
      t.column :created_by_id,  :integer,       :null => false
      t.timestamps
    end
    add_index :stores, [:store_object_id, :o_id]
    
    create_table :store_objects do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.column :note,         :string, :limit => 250,   :null => true
      t.timestamps
    end
    add_index :store_objects, [:name],   :unique => true

    create_table :store_files do |t|
      t.column :data,     :binary,        :limit => 100.megabytes
      t.column :md5,      :string,        :limit => 60,  :null => false
      t.timestamps
    end
    add_index :store_files, [:md5],   :unique => true

  end

  def down
    drop_table :stores
    drop_table :store_objects
    drop_table :store_files
  end
end
