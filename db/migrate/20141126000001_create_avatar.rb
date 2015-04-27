class CreateAvatar < ActiveRecord::Migration
  def up
    create_table :avatars do |t|
      t.column :o_id,               :integer,                 null: false
      t.column :object_lookup_id,   :integer,                 null: false
      t.column :default,            :boolean,                 null: false, default: false
      t.column :deletable,          :boolean,                 null: false, default: true
      t.column :inital,             :boolean,                 null: false, default: false
      t.column :store_full_id,      :integer,                 null: true
      t.column :store_resize_id,    :integer,                 null: true
      t.column :store_hash,         :string, limit: 32,    null: true
      t.column :source,             :string, limit: 100,   null: false
      t.column :source_url,         :string, limit: 512,   null: true
      t.column :updated_by_id,      :integer,                 null: false
      t.column :created_by_id,      :integer,                 null: false
      t.timestamps
    end
    add_index :avatars, [:o_id, :object_lookup_id]
    add_index :avatars, [:store_hash]
    add_index :avatars, [:source]
    add_index :avatars, [:default]
  end

  def down
  end
end
