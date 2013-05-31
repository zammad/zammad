class Taskbar < ActiveRecord::Migration
  def up
    create_table :taskbars do |t|
      t.column :user_id,              		:integer,   :null => false
      t.column :last_contact,				:datetime,	:null => false
      t.column :client_id,					:string, 	:limit => 100, :null => false
      t.column :type,                       :string,    :limit => 100, :null => false
      t.column :type_id,                    :string,    :limit => 100, :null => false
      t.column :callback,                   :string,    :limit => 100, :null => false
      t.column :notify,                     :boolean,   :null => false, :default => false
      t.column :active,                     :boolean,   :null => false, :default => false
      t.column :state,    					:string, 	:limit => 8000,:null => true
      t.column :params,						:string, 	:limit => 2000,:null => true
      t.timestamps
    end

  end

  def down
    drop_table :taskbars
  end
end
