class TagsCreate < ActiveRecord::Migration
  def up
    create_table :tags do |t|
      t.references :tag_item,                           :null => false
      t.references :tag_object,                         :null => false
      t.column :o_id,                       :integer,   :null => false
      t.column :created_by_id,              :integer,   :null => false
      t.timestamps
    end
    add_index :tags, [:o_id]
    add_index :tags, [:tag_object_id]
    
    create_table :tag_objects do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.timestamps
    end
    add_index :tag_objects, [:name],    :unique => true

    create_table :tag_items do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.timestamps
    end
    add_index :tag_items, [:name],      :unique => true
  end

  def down
  end
end
