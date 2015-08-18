
class CreateUserDevices < ActiveRecord::Migration
  def up
    create_table :user_devices do |t|
      t.references :user,             null: false
      t.string  :name,                 limit: 250, null: false
      t.string  :os,                   limit: 150, null: true
      t.string  :browser,              limit: 250, null: true
      t.string  :location,             limit: 150, null: true
      t.string  :device_details,       limit: 2500, null: true
      t.string  :location_details,     limit: 2500, null: true
      t.string  :fingerprint,          limit: 160, null: true
      t.string  :user_agent,           limit: 250, null: true
      t.string  :ip,                   limit: 160, null: true
      t.timestamps
    end
    add_index :user_devices, [:user_id]
    add_index :user_devices, [:os, :browser, :location]
    add_index :user_devices, [:fingerprint]
    add_index :user_devices, [:updated_at]
    add_index :user_devices, [:created_at]
  end

  def down
    drop_table :user_devices
  end
end
