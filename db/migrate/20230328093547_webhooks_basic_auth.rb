# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class WebhooksBasicAuth < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :webhooks, :basic_auth_username, :string, limit: 250, null: true
    add_column :webhooks, :basic_auth_password, :string, limit: 250, null: true
    Webhook.reset_column_information
  end
end
