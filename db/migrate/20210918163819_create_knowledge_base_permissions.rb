# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Using older 5.0 migration to stick to Integer primary keys. Otherwise migration fails in MySQL.
class CreateKnowledgeBasePermissions < ActiveRecord::Migration[5.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    create_table :knowledge_base_permissions do |t|
      t.references :permissionable, polymorphic: true, null: false, index: { name: 'index_knowledge_base_permissions_on_permissionable' }
      t.references :role, null: false, foreign_key: { to_table: :roles }

      t.string 'access', limit: 50, default: 'full', null: false
      t.index 'access'

      t.index %i[role_id permissionable_id permissionable_type], unique: true, name: 'knowledge_base_permissions_uniqueness'

      t.timestamps limit: 3
    end

    Permission.where(name: 'knowledge_base.reader').update_all(allow_signup: true) # rubocop:disable Rails/SkipsModelValidations
  end
end
