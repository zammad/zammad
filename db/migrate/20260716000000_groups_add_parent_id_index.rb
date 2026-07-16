# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class GroupsAddParentIdIndex < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # Covers the child-lookup joins of the recursive tree walks (Group#all_children,
    # Group.unselectable_as_parent), which step through parent_id once per tree level.
    add_index :groups, :parent_id

    Group.reset_column_information
  end
end
