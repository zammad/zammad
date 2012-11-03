class OverviewUpdate2 < ActiveRecord::Migration
  def up
      add_column :overviews, :group_by,            :string,  :limit => 250,  :null => true
  end

  def down
  end
end
