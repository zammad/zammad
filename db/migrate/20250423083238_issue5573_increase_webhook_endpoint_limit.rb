# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue5573IncreaseWebhookEndpointLimit < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_column :webhooks, :endpoint, :string, limit: 2000, null: false
    Webhook.reset_column_information
  end
end
