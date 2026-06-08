# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AdminPermissionAlignment < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.find_by(name: 'admin.checklist')&.update!(preferences: { prio: 1095 })
    Permission.find_by(name: 'admin.channel_google')&.update!(label: 'Google Email')
    Permission.find_by(name: 'admin.channel_microsoft365')&.update!(label: 'Microsoft 365 IMAP Email', preferences: { prio: 1255 })
    Permission.find_by(name: 'admin.channel_microsoft_graph')&.update!(label: 'Microsoft 365 Graph Email', preferences: { prio: 1250 })
  end
end
