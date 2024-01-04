# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class AddCustomPayloadWebhooks < ActiveRecord::Migration[6.1]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    change_table :webhooks do |t|
      t.column :custom_payload, :text, limit: 500.kilobytes + 1, null: true
    end

    Webhook.reset_column_information
  end
end
