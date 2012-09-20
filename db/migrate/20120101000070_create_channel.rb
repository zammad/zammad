class CreateChannel < ActiveRecord::Migration
  def up
    
    create_table :channels do |t|
      t.references :group,                                :null => true
      t.column :adapter,        :string, :limit => 100,   :null => false
      t.column :area,           :string, :limit => 100,   :null => false
      t.column :options,        :string, :limit => 2000,  :null => true
      t.column :active,         :boolean,                 :null => false, :default => true
      t.column :updated_by_id,  :integer,                 :null => false
      t.column :created_by_id,  :integer,                 :null => false
      t.timestamps
    end
    add_index :channels, [:area]
    add_index :channels, [:adapter]

  end

  def down
    drop_table :channels
  end
end
