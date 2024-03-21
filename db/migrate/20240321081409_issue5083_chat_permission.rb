# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Issue5083ChatPermission < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    parent_chat_permission = Permission.find_by(name: 'chat')
    chat_permissions       = Permission.where("name LIKE 'chat.%'")

    Role.find_each do |role|
      next if role.permissions.exclude?(parent_chat_permission)

      role.permissions -= [parent_chat_permission]
      role.permissions += chat_permissions
    end
  end
end
