# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ContentTranslationPerProviderSettings, type: :db_migration do
  let(:new_settings)    { %w[content_translation_provider content_translation_deepl_config content_translation_libre_translate_config] }
  let(:shared_settings) { described_class::SHARED_SETTINGS }

  before do
    Setting.where(name: new_settings).destroy_all
    Permission.find_by(name: 'admin.ai_assistance_translation')&.destroy

    Setting.create!(
      title:       'Translation Service Config',
      name:        'content_translation_service_config',
      area:        'Integration::Translation',
      description: 'Stores the translation service configuration.',
      options:     {},
      state:       { 'provider' => 'deepl', 'api_key' => 'secret-key', 'tier' => 'free' },
      preferences: { authentication: true, permission: ['admin.integration'] },
      frontend:    false,
    )

    Setting.where(name: shared_settings).find_each do |setting|
      setting.update!(preferences: setting.preferences.merge(permission: ['admin.integration']))
    end

    Setting.set('content_translation_service', true, validate: false)
  end

  it 'adds the AI translation permission' do
    expect { migrate }.to change { Permission.exists?(name: 'admin.ai_assistance_translation') }.to(true)
  end

  it 'removes the combined config without carrying it over', :aggregate_failures do
    migrate

    expect(Setting.exists?(name: 'content_translation_service_config')).to be(false)
    expect(Setting.get('content_translation_deepl_config')).to eq({})
    expect(Setting.get('content_translation_provider')).to eq('')
  end

  it 'switches translation off' do
    expect { migrate }.to change { Setting.get('content_translation_service') }.from(true).to(false)
  end

  it 'adds the per-provider settings, with the configs on the integration permission only', :aggregate_failures do
    migrate

    expect(Setting.find_by(name: 'content_translation_provider').preferences[:permission])
      .to eq(['admin.integration', 'admin.ai_assistance_translation'])
    expect(Setting.where(name: %w[content_translation_deepl_config content_translation_libre_translate_config]).map { |s| s.preferences[:permission] })
      .to all(eq(['admin.integration']))
  end

  it 'lets either permission change the shared settings' do
    migrate

    expect(Setting.where(name: shared_settings).map { |s| s.preferences[:permission] })
      .to all(eq(['admin.integration', 'admin.ai_assistance_translation']))
  end
end
