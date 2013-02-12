class ChangeUserLoginFailed < ActiveRecord::Migration
  def up
    add_column :users, :login_failed, :integer, :null => false, :default => 0
  end
  def down
  end
end
