# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class UpdateUploadCacheObjectId < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_column :stores, :o_id, :string, limit: 255
    Store.reset_column_information
  end
end
