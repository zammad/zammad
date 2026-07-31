# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CreateAIProviderConnections, db_strategy: :reset, type: :db_migration do
  before do
    drop_table :ai_feature_providers, if_exists: true
    drop_table :ai_provider_connections, if_exists: true

    Setting.new(
      title:       __('AI Provider Config'),
      name:        'ai_provider_config',
      area:        'AI::Provider',
      description: __('Stores the AI provider configuration.'),
      options:     {},
      state:       {},
      preferences: {
        permission: ['admin.ai_provider'],
      },
      frontend:    false,
    ).save(validate: false)

    Setting.set('ai_provider_config', ai_provider_config, validate: false)
  end

  context 'when a provider was configured' do
    let(:ai_provider_config) { { provider: 'open_ai', token: 'sk-test', model: 'gpt-4o' } }

    it 'creates a single default connection named after the provider' do
      migrate
      expect(AI::ProviderConnection.find_by(name: 'open_ai'))
        .to have_attributes(provider: 'open_ai', default_chat: true, default_embedding: true, default_ocr: true)
    end

    it 'copies the config without the provider key' do
      migrate
      expect(AI::ProviderConnection.find_by(name: 'open_ai').config).to eq('token' => 'sk-test', 'model' => 'gpt-4o')
    end

    it 'seeds no per-feature routing rows (for_chat falls back to default)' do
      migrate
      expect(AI::FeatureProvider.count).to be_zero
    end

    it 'removes the obsolete setting' do
      expect { migrate }
        .to change { Setting.exists?(name: 'ai_provider_config') }
        .to(false)
    end

    it 'is idempotent' do
      migrate
      expect { migrate }.not_to change(AI::ProviderConnection, :count)
    end
  end

  context 'when the Zammad AI provider was configured on SaaS' do
    let(:ai_provider_config) { { provider: 'zammad_ai', token: 'sk-test' } }

    before do
      Setting.set('system_online_service', true)
    end

    it 'converts the platform-provisioned provider into the default connection' do
      migrate
      expect(AI::ProviderConnection.find_by(name: 'zammad_ai')).to have_attributes(provider: 'zammad_ai', default_chat: true)
    end
  end

  context 'when the provider had image text recognition enabled' do
    # The flag was stored by a form switch, so it can be a string.
    let(:ai_provider_config) { { provider: 'open_ai', token: 'sk-test', ocr_active: 'true' } }

    it 'carries the flag over to the summary options as a boolean' do
      migrate
      expect(Setting.get('ai_assistance_ticket_summary_config')).to include('ocr_active' => true)
    end

    it 'keeps the other summary options untouched' do
      migrate
      expect(Setting.get('ai_assistance_ticket_summary_config'))
        .to include('customer_sentiment' => true, 'generate_on' => 'on_ticket_detail_opening')
    end

    it 'leaves the option disabled in the initial state' do
      migrate
      expect(Setting.find_by(name: 'ai_assistance_ticket_summary_config').state_initial[:value])
        .to include('ocr_active' => false)
    end
  end

  context 'when no provider was configured' do
    let(:ai_provider_config) { {} }

    it 'creates no connections' do
      migrate
      expect(AI::ProviderConnection.count).to be_zero
    end

    it 'creates no routing rows' do
      migrate
      expect(AI::FeatureProvider.count).to be_zero
    end

    it 'removes the obsolete setting' do
      expect { migrate }
        .to change { Setting.exists?(name: 'ai_provider_config') }
        .to(false)
    end

    it 'leaves image text recognition disabled' do
      migrate
      expect(Setting.get('ai_assistance_ticket_summary_config')).to include('ocr_active' => false)
    end
  end
end
