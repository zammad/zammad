class UpdateUserDevices < ActiveRecord::Migration
  def up
    add_column :user_devices, :location, :string, limit: 150, null: true
    remove_column :user_devices, :country
    add_index :user_devices, [:os, :browser, :location]
    UserDevice.reset_column_information
  end

end
