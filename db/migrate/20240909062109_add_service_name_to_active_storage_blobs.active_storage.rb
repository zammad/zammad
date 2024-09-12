# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# This migration comes from active_storage (originally 20190112182829)
class AddServiceNameToActiveStorageBlobs < ActiveRecord::Migration[6.0]
  def up
    return if !table_exists?(:active_storage_blobs)

    return if column_exists?(:active_storage_blobs, :service_name)

    add_column :active_storage_blobs, :service_name, :string

    if (configured_service = ActiveStorage::Blob.service.name)
      ActiveStorage::Blob.unscoped.update_all(service_name: configured_service) # rubocop:disable Rails/SkipsModelValidations
    end

    change_column :active_storage_blobs, :service_name, :string, null: false

  end

  def down
    return if !table_exists?(:active_storage_blobs)

    remove_column :active_storage_blobs, :service_name

    ActiveStorageBlob.reset_column_information
  end
end
