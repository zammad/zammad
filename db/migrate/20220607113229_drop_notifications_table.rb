# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class DropNotificationsTable < ActiveRecord::Migration[6.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    drop_table :notifications
  end
end
