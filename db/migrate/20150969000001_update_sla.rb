class UpdateSla < ActiveRecord::Migration
  def up
    add_column :slas, :calendar_id, :integer, null: false
    remove_column :slas, :timezone
    remove_column :slas, :data
    remove_column :slas, :active
  end
end
