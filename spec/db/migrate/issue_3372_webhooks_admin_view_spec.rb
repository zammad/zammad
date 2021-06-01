# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3372WebhooksAdminView, type: :db_migration do

  let(:trigger_webhook_config) do
    {
      'endpoint'   => 'https://example.com/webhook',
      'token'      => '53Cr3T',
      'verify_ssl' => false,
    }
  end

  let(:webhook_attributes) do
    {
      endpoint:        trigger_webhook_config['endpoint'],
      signature_token: trigger_webhook_config['token'],
      ssl_verify:      trigger_webhook_config['verify_ssl'],
    }
  end

  let!(:trigger) do
    Trigger.without_callback(:create, :before, :validate_perform) do
      create(:trigger, perform: {
               'notification.webhook' => trigger_webhook_config
             })
    end
  end

  it 'Creates Webhook object from mapped Trigger configuration' do
    migrate do |migration|
      allow(migration).to receive(:create_webhooks_table)
    end

    expect(Webhook.last).to have_attributes(**webhook_attributes)
  end

  it 'Migrates Trigger#perform Webhook configuration to new structure' do
    migrate do |migration|
      allow(migration).to receive(:create_webhooks_table)
    end

    expect(trigger.reload.perform['notification.webhook']['webhook_id']).to eq(Webhook.last.id)
  end
end
