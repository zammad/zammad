# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class PGPKeyEmailAddresses < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    migrate_db_schema_pre
    migrate_db_data
    migrate_db_schema_post
  end

  private

  def migrate_db_schema_pre
    add_column :pgp_keys, :name, :string, limit: 3000, null: true

    if Rails.application.config.db_column_array
      add_column :pgp_keys, :email_addresses, :string, null: true, array: true
    else
      add_column :pgp_keys, :email_addresses, :json, null: true
    end

    PGPKey.reset_column_information
  end

  def migrate_db_data
    PGPKey.all.each do |key|
      next if key.name.present?

      key.name = key.uids.split(',').join(', ')
      key.prepare_email_addresses

      key.save!
    end
  end

  def migrate_db_schema_post
    change_column_null :pgp_keys, :name, false
    remove_index :pgp_keys, [:uids]
    remove_column :pgp_keys, :uids

    PGPKey.reset_column_information
  end
end
