# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3940AddIndex < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_index :groups_users, %i[user_id group_id access]
  end
end
