class CreateActivityStream < ActiveRecord::Migration
  def up
    
    create_table :activity_streams do |t|
      t.references :activity_stream_type,                   :null => false
      t.references :activity_stream_object,                 :null => false
      t.references :role,                                   :null => true
      t.references :group,                                  :null => true
      t.column :o_id,                           :integer,   :null => false
      t.column :created_by_id,                  :integer,   :null => false
      t.timestamps
    end
    add_index :activity_streams, [:o_id]
    add_index :activity_streams, [:created_by_id]
    add_index :activity_streams, [:role_id]
    add_index :activity_streams, [:group_id]
    add_index :activity_streams, [:created_at]
    add_index :activity_streams, [:activity_stream_object_id]
    add_index :activity_streams, [:activity_stream_type_id]

    create_table :activity_stream_types do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.timestamps
    end
    add_index :activity_stream_types, [:name],     :unique => true

    create_table :activity_stream_objects do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.column :note,         :string, :limit => 250,   :null => true
      t.timestamps
    end
    add_index :activity_stream_objects, [:name],   :unique => true

  end

  def down
    drop_table :activity_streams
    drop_table :activity_stream_objects
    drop_table :activity_stream_types
  end
end
