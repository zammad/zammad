class PermissionActive < ActiveRecord::Migration[4.2]
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :permissions, :active, :boolean, null: false, default: true

    Cache.clear
  end
end
