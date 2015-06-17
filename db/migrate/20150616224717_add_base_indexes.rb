class AddBaseIndexes < ActiveRecord::Migration
  def change
    add_index :users, [:organization_id]
    add_index :roles_users, [:user_id]
    add_index :roles_users, [:role_id]
    add_index :groups_users, [:user_id]
    add_index :groups_users, [:group_id]
    add_index :organizations_users, [:user_id]
    add_index :organizations_users, [:organization_id]

  end
end
