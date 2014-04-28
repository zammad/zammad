class UpdateStorage < ActiveRecord::Migration
  def up
    change_column :store_files, :data,              :binary, :limit => 200.megabytes, :null => true
    add_column    :store_files, :file_system,       :boolean,                         :null => false, :default => false
  end

  def down
  end
end
