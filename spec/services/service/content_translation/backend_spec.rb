# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::ContentTranslation::Backend do
  let(:deepl_config) { { 'api_key' => 'deepl-key', 'tier' => 'free' } }
  let(:libre_config) { { 'url' => 'https://translate.example.com', 'api_key' => 'libre-key' } }

  before do
    Setting.set('content_translation_deepl_config', deepl_config, validate: false)
    Setting.set('content_translation_libre_translate_config', libre_config, validate: false)
  end

  describe '.configured' do
    it 'is nil without an active provider' do
      expect(described_class.configured).to be_nil
    end

    {
      'ai'              => Service::ContentTranslation::Backend::AI,
      'deepl'           => Service::ContentTranslation::Backend::DeepL,
      'libre_translate' => Service::ContentTranslation::Backend::LibreTranslate,
    }.each do |provider, backend|
      it "resolves #{provider} to its backend" do
        Setting.set('content_translation_provider', provider)

        expect(described_class.configured).to eq(backend)
      end
    end
  end

  describe '.locked_provider_name' do
    it 'is the stored name, also before the settings cache has seen it' do
      store_setting_behind_cache('content_translation_provider', 'deepl')

      expect(described_class.locked_provider_name).to eq('deepl')
    end
  end

  describe '.non_ai_backend_names' do
    it 'names the backends that answer without an AI feature' do
      expect(described_class.non_ai_backend_names).to contain_exactly('deepl', 'libre_translate')
    end
  end

  describe 'the config of each backend' do
    it 'is read from the setting of that backend', :aggregate_failures do
      expect(Service::ContentTranslation::Backend::DeepL.config).to eq(deepl_config)
      expect(Service::ContentTranslation::Backend::LibreTranslate.config).to eq(libre_config)
    end

    it 'is empty for the AI backend, which is configured with the AI provider' do
      expect(Service::ContentTranslation::Backend::AI.config).to eq({})
    end

    # Switching keeps each config, so the one that was active before is still there afterwards.
    it 'survives switching to another provider', :aggregate_failures do
      Setting.set('content_translation_provider', 'deepl')
      Setting.set('content_translation_provider', 'libre_translate')

      expect(Setting.get('content_translation_deepl_config')).to eq(deepl_config)
      expect(Service::ContentTranslation::Backend::DeepL.config).to eq(deepl_config)
    end
  end
end
