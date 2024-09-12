# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# This migration comes from active_storage (originally 20211119233751)
class RemoveNotNullOnActiveStorageBlobsChecksum < ActiveRecord::Migration[6.0]
  def change
    return if !table_exists?(:active_storage_blobs)

    change_column_null(:active_storage_blobs, :checksum, true)
  end
end
