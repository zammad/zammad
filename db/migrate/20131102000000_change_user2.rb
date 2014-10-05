class ChangeUser2 < ActiveRecord::Migration
  def up
    add_column :users, :image_source, :string, :limit => 200, :null => true
    add_index :users, [:image]
    User.all.each {|user|
      puts "Update user #{user.login}"
      user.image_source = user.image
      user.save
    }
  end

  def down
  end
end
