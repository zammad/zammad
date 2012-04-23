class CreateToken < ActiveRecord::Migration
  def up
    create_table :tokens do |t|
      t.references :user,                 :null => false
      t.string :name,     :limit => 100,  :null => false
      t.string :action,   :limit => 40,   :null => false
      t.timestamps
    end
    add_index :tokens, :user_id
    add_index :tokens, [:name, :action], :unique => true
    add_index :tokens, :created_at
  end

  def down
    drop_table :tokens
  end
end
