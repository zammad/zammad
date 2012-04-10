class CreateSetting < ActiveRecord::Migration
  def up
    create_table :settings do |t|
      t.column :title,          :string, :limit => 200,  :null => false
      t.column :name,           :string, :limit => 200,  :null => false
      t.column :area,           :string, :limit => 100,  :null => false
      t.column :description,    :string, :limit => 2000, :null => false
      t.column :options,        :string, :limit => 2000, :null => true
      t.column :state,          :string, :limit => 2000, :null => true
      t.column :state_initial,  :string, :limit => 2000, :null => true
      t.column :frontend,       :boolean,                :null => false
      t.timestamps
    end
    add_index :settings, [:name], :unique => true
    add_index :settings, [:area]
    add_index :settings, [:frontend]
  end

  def down
    drop_table :settings
  end
end
