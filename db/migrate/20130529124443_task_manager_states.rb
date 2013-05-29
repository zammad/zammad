class TaskManagerStates < ActiveRecord::Migration
  def up
    create_table :taskbars do |t|
      t.column :user_id,              		:integer,   :null => false
      t.column :last_contact,				:datetime,	:null => false
      t.column :client_id,					:string, 	:null => false
      t.column :state,    					:string, 	:limit => 8000,:null => true
      t.column :params,						:string, 	:limit => 2000,:null => true
      t.timestamps
    end

  end

  def down
    drop_table :taskbars
  end
end
