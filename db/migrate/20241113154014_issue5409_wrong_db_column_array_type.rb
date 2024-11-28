# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Issue5409WrongDbColumnArrayType < ActiveRecord::Migration[7.1]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    # Do not execute on unsupported backends.
    return if !Rails.application.config.db_column_array

    migrate_smime_certificates_email_addresses_column
    migrate_pgp_keys_email_addresses_column
    migrate_public_links_screen_column
    migrate_object_attribute_multiselect_columns
    migrate_object_attribute_multi_tree_select_columns
  end

  private

  def migrate_smime_certificates_email_addresses_column
    return if ActiveRecord::Base.connection.columns(:smime_certificates).find { |c| c.name == 'email_addresses' }.type == :string

    change_column :smime_certificates, :email_addresses, :string, null: true, array: true

    SMIMECertificate.reset_column_information
  end

  def migrate_pgp_keys_email_addresses_column
    return if ActiveRecord::Base.connection.columns(:pgp_keys).find { |c| c.name == 'email_addresses' }.type == :string

    change_column :pgp_keys, :email_addresses, :string, null: true, array: true

    PGPKey.reset_column_information
  end

  def migrate_public_links_screen_column
    return if ActiveRecord::Base.connection.columns(:public_links).find { |c| c.name == 'screen' }.type == :string

    change_column :public_links, :screen, :string, null: false, array: true

    PublicLink.reset_column_information
  end

  def migrate_object_attribute_multiselect_columns
    migrate_object_attribute_columns('multiselect')
  end

  def migrate_object_attribute_multi_tree_select_columns
    migrate_object_attribute_columns('multi_tree_select')
  end

  def migrate_object_attribute_columns(data_type)
    ObjectManager::Attribute.where(data_type:).each do |attribute|
      object = attribute.object_lookup.name.constantize
      object_table = object.table_name.to_sym

      table_column = ActiveRecord::Base.connection.columns(object_table).find { |c| c.name == attribute.name }

      # In case the table column does not exist in the schema, skip the check and data type change (#5430).
      #   This can happen if the table column migration was not executed after adding an object manager attribute.
      next if !table_column || table_column.type == :string

      change_column object_table, attribute.name.to_sym, :string, null: table_column.null, array: table_column.array # rubocop:disable Zammad/ExistsResetColumnInformation

      object.send(:reset_column_information)
    end
  end
end
