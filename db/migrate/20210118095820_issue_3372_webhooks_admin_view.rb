# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3372WebhooksAdminView < ActiveRecord::Migration[5.2]

  def up
    return if !Setting.exists?(name: 'system_init_done')

    create_webhooks_table

    record_upgrade

    Permission.create_if_not_exists(
      name:        'admin.webhook',
      note:        'Manage %s',
      preferences: {
        translations: ['Webhooks']
      },
    )
  end

  def create_webhooks_table
    create_table :webhooks do |t|
      t.column :name,                       :string, limit: 250,  null: false
      t.column :endpoint,                   :string, limit: 300,  null: false
      t.column :signature_token,            :string, limit: 200,  null: true
      t.column :ssl_verify,                 :boolean,             null: false, default: true
      t.column :note,                       :string, limit: 500,  null: true
      t.column :active,                     :boolean,             null: false, default: true
      t.column :updated_by_id,              :integer,             null: false
      t.column :created_by_id,              :integer,             null: false
      t.timestamps limit: 3, null: false
    end
  end

  def record_upgrade
    Trigger.all.find_each do |trigger|
      next if trigger.perform.dig('notification.webhook', 'endpoint').blank?

      webhook = webhook_create(
        source: trigger.name,
        config: trigger.perform['notification.webhook'],
      )
      trigger.perform['notification.webhook'] = { webhook_id: webhook.id }
      trigger.save!
    end
  end

  def webhook_create(source:, config:)
    Webhook.create!(
      name:            "Webhook '#{source}'",
      endpoint:        config['endpoint'],
      signature_token: config['token'],
      ssl_verify:      config['verify_ssl'] || false,
      active:          true,
      created_by_id:   1,
      updated_by_id:   1,
    )
  end

end
