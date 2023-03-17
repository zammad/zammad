# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3141MultiLdap < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_table
    migrate_config
    remove_config
  end

  def add_table
    create_table :ldap_sources do |t|
      t.string :name,                     limit: 100, null: false
      t.text   :preferences,              limit: 5.megabytes + 1, null: true
      t.boolean :active,                  null: false, default: true
      t.integer :prio,                    null: false
      t.integer :updated_by_id,           null: false
      t.integer :created_by_id,           null: false
      t.timestamps limit: 3, null: false
    end
    add_index :ldap_sources, [:name], unique: true
    add_foreign_key :ldap_sources, :users, column: :created_by_id
    add_foreign_key :ldap_sources, :users, column: :updated_by_id
  end

  def migrate_config
    config = Setting.get('ldap_config')
    return if config.blank?

    UserInfo.current_user_id = 1
    source = LdapSource.create!(
      name:        'LDAP #1',
      preferences: config
    )
    update_user_source(source)
  end

  def update_user_source(source)
    User.where(source: 'Ldap').update_all(source: "Ldap::#{source.id}") # rubocop:disable Rails/SkipsModelValidations
    Rails.cache.clear
  end

  def remove_config
    Setting.find_by(name: 'ldap_config').destroy
  end
end
