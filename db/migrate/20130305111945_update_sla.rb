class UpdateSla < ActiveRecord::Migration
  def up
    add_column :slas, :first_response_time, :integer, :null => true
    add_column :slas, :update_time,         :integer, :null => true
    add_column :slas, :close_time,          :integer, :null => true
  end

  def down
  end
end
