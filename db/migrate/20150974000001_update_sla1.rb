class UpdateSla1 < ActiveRecord::Migration
  def up
    rename_column :slas, :close_time, :solution_time
  end
end
