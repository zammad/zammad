# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class EnhancedPermissions < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_column_null :groups_users, :user_id, false
    change_column_null :groups_users, :group_id, false
    add_column :groups_users, :access, :string, limit: 50, null: false, default: 'full'
    add_index :groups_users, [:access]
    UserGroup.connection.schema_cache.clear!
    UserGroup.reset_column_information

    create_table :roles_groups, id: false do |t|
      t.references :role,                null: false
      t.references :group,               null: false
      t.string :access, limit: 50, null: false, default: 'full'
    end
    add_index :roles_groups, [:role_id]
    add_index :roles_groups, [:group_id]
    add_index :roles_groups, [:access]

    Cache.clear
  end
end
