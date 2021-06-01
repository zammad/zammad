# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class PermissionActive < ActiveRecord::Migration[4.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :permissions, :active, :boolean, null: false, default: true

    Cache.clear
  end
end
