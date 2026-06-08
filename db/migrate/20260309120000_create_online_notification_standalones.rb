# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CreateOnlineNotificationStandalones < ActiveRecord::Migration[7.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    create_table :online_notification_standalones, id: :integer do |t|
      t.jsonb 'data', null: false, default: {}
      t.string 'kind', null: false
      t.timestamps limit: 3, null: false
    end
  end
end
