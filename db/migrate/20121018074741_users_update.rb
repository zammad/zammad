class UsersUpdate < ActiveRecord::Migration
  def up
    add_column :users, :last_login,       :timestamp,              :null => true
  end

  def down
  end
end
