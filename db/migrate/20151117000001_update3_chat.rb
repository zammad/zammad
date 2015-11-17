class Update3Chat < ActiveRecord::Migration
  def up
    add_column :chats, :preferences, :string, limit: 5000, null: true
  end
end
