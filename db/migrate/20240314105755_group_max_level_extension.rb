# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class GroupMaxLevelExtension < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    groups_name_limit = (160 * 10) + (2 * 9) # max depth of 10 and 9 delimiters in between

    change_column :groups, :name, :string, limit: groups_name_limit, null: false
    Group.reset_column_information
  end
end
