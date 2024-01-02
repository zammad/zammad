# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class AddPreDefinedWebhookColumns < ActiveRecord::Migration[6.1]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    change_table :webhooks do |t|
      t.column :pre_defined_webhook_type, :string, limit: 250,             null: true
      t.column :customized_payload,       :boolean,                        null: false, default: false
      t.column :preferences,              :text, limit: 500.kilobytes + 1, null: true
    end

    Webhook.reset_column_information
  end
end
