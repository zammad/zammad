# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class AddTaskbarMeta < ActiveRecord::Migration[4.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :taskbars, :preferences, :text, limit: 5.megabytes + 1, null: true
    add_index :taskbars, [:key]

    Rails.cache.clear
  end
end
