class CreateSla < ActiveRecord::Migration
  def up
    create_table :slas do |t|
      t.column :name,               :string, :limit => 150,   :null => true
#      t.column :first_response_time, :integer,                 :null => true
#      t.column :update_time,        :integer,                 :null => true
#      t.column :close_time,         :integer,                 :null => true
      t.column :condition,          :string, :limit => 5000,  :null => true
      t.column :data,               :string, :limit => 5000,  :null => true
      t.column :active,             :boolean,                 :null => false, :default => true
      t.column :updated_by_id,      :integer,                 :null => false
      t.column :created_by_id,      :integer,                 :null => false
      t.timestamps
    end
    add_index :slas, [:name], :unique => true
  end

  def down
  end
end
