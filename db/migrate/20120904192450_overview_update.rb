class OverviewUpdate < ActiveRecord::Migration
  def up
    add_column :overviews, :role_id,          :integer, :null => true
  end

  def down
  end
end
