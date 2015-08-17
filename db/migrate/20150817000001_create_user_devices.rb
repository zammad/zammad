
class CreateUserDevices < ActiveRecord::Migration
  def up
    create_table :user_devices do |t|
      t.references :user,             null: false
      t.string  :name,                 limit: 250, null: false
      t.string  :os,                   limit: 150, null: true
      t.string  :browser,              limit: 250, null: true
      t.string  :country,              limit: 150, null: true
      t.string  :device_details,       limit: 2500, null: true
      t.string  :location_details,     limit: 2500, null: true
      t.timestamps
    end
    add_index :user_devices, [:user_id]
    add_index :user_devices, [:os, :browser, :country]
    add_index :user_devices, [:updated_at]
  end

  def down
    drop_table :user_devices
  end
end
