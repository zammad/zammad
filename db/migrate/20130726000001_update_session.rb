class UpdateSession < ActiveRecord::Migration
  def up
    add_column :sessions, :request_type,      :integer, null: true
    add_index :sessions, :request_type
  end
  def down
  end
end
