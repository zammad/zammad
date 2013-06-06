class SlaTimezone < ActiveRecord::Migration
  def up
    add_column :slas, :timezone,     :string, :limit => 50, :null => true
  end

  def down
    remove_column :slas, :timezone
  end
end
