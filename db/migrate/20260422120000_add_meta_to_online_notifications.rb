# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddMetaToOnlineNotifications < ActiveRecord::Migration[7.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    add_column :online_notifications, :meta, :jsonb, null: false, default: {}
    OnlineNotification.reset_column_information
  end
end
