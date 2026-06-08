# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddBearerTokenAndHttpMethodToWebhooks < ActiveRecord::Migration[7.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    change_table :webhooks do |t|
      t.column :bearer_token, :string, limit: 2500, null: true
      t.column :http_method,  :string, limit: 10, null: false, default: 'post'
    end

    Webhook.reset_column_information
  end
end
