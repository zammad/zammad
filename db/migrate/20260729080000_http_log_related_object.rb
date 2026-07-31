# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HttpLogRelatedObject < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup (fresh installs get the columns from CreateBase)
    return if !Setting.exists?(name: 'system_init_done')

    add_column :http_logs, :related_object_type, :string, limit: 100, null: true, if_not_exists: true
    add_column :http_logs, :related_object_id, :integer, null: true, if_not_exists: true

    add_index :http_logs, %i[related_object_type related_object_id], if_not_exists: true

    HttpLog.reset_column_information
  end
end
