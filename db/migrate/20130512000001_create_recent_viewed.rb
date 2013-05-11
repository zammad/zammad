class CreateRecentViewed < ActiveRecord::Migration
  def up
    create_table :recent_views do |t|
      t.references :recent_view_object,                 :null => false
      t.column :o_id,                       :integer,   :null => false
      t.column :created_by_id,              :integer,   :null => false
      t.timestamps
    end
    add_index :recent_views, [:o_id]
    add_index :recent_views, [:created_by_id]
    add_index :recent_views, [:created_at]
    add_index :recent_views, [:recent_view_object_id]

    create_table :recent_view_objects do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.column :note,         :string, :limit => 250,   :null => true
      t.timestamps
    end
    add_index :recent_view_objects, [:name],   :unique => true
  end

  def down
    drop_table :recent_views
    drop_table :recent_view_objects
  end
end
