# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class AddGroupDirectionToOverviews < ActiveRecord::Migration[5.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :overviews, :group_direction, :string, limit: 250, null: true
  end
end
