class CreateOnlineNotification < ActiveRecord::Migration
  def up
    create_table :online_notifications do |t|
      t.column :o_id,               :integer,                 :null => false
      t.column :object_lookup_id,   :integer,                 :null => false
      t.column :type_lookup_id,     :integer,                 :null => false
      t.column :user_id,            :integer,                 :null => false
      t.column :seen,               :boolean,                 :null => false, :default => false
      t.column :created_by_id,      :integer,                 :null => false
      t.timestamps
    end
    add_index :online_notifications, [:user_id]
  end

  def down
  end
end
