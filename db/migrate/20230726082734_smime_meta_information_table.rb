# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SMIMEMetaInformationTable < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    migrate_table
  end

  private

  def migrate_table
    change_table :smime_certificates do |t|
      remove_columns(t)
      rename_columns(t)
      add_columns(t)
    end

    SMIMECertificate.reset_column_information
  end

  def remove_columns(t)
    t.remove_index :modulus if t.index_exists?(:modulus)
    t.remove_index :subject if t.index_exists?(:subject)

    t.remove :subject, :doc_hash, :not_before_at, :not_after_at
  end

  def rename_columns(t)
    t.rename :modulus, :uid
    t.rename :raw, :pem
  end

  def add_columns(t)
    if Rails.application.config.db_column_array
      t.column :email_addresses, :string, null: true, array: true
    else
      t.column :email_addresses, :json, null: true
    end

    t.string :issuer_hash,  limit: 128, null: true
    t.string :subject_hash, limit: 128, null: true

    t.index [:uid]
  end
end
