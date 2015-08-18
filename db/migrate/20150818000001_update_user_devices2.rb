class UpdateUserDevices2 < ActiveRecord::Migration
  def up
    add_column :user_devices, :user_agent, :string, limit: 250, null: true
    add_column :user_devices, :ip, :string, limit: 160, null: true
    add_column :user_devices, :fingerprint, :string, limit: 160, null: true
    add_index :user_devices, [:fingerprint]
    add_index :user_devices, [:created_at]
    UserDevice.reset_column_information
  end

end
