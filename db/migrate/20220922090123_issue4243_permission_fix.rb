# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4243PermissionFix < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Role.find_each do |role|
      next if role.groups.blank?

      agent_permission = Permission.find_by(name: 'ticket.agent')
      next if role.permissions.include?(agent_permission)

      role.groups = []
    end
  end
end
