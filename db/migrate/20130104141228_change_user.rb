class ChangeUser < ActiveRecord::Migration
  def up
    add_column :users, :locale, :string, :limit => 10,  :null => true
  end

  def down
  end
end
