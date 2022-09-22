# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Issue4243PermissionFix < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Role.find_each do |role|
      next if role.groups.blank?

      role.permissions |= Permission.where(name: 'ticket.agent')
    end
  end
end
