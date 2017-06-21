class TreeSelect < ActiveRecord::Migration
  def up
    change_column :object_manager_attributes, :data_option, :text, limit: 800.kilobytes + 1, null: true
    change_column :object_manager_attributes, :data_option_new, :text, limit: 800.kilobytes + 1, null: true
  end
end
