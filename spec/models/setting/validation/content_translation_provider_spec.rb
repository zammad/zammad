# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::ContentTranslationProvider do
  let(:setting_name) { 'content_translation_provider' }

  shared_examples 'not raising an error' do |value:|
    it 'does not raise an error' do
      expect { Setting.set(setting_name, value) }.not_to raise_error
    end
  end

  shared_examples 'raising an error' do |value:, message:|
    it 'raises an error' do
      expect { Setting.set(setting_name, value) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{#{Regexp.escape(message)}})
    end
  end

  context 'with no provider' do
    it_behaves_like 'not raising an error', value: ''

    context 'with the translation service switched on' do
      before do
        Setting.set(setting_name, 'ai')
        Setting.set('content_translation_service', true)
      end

      it_behaves_like 'raising an error', value: '', message: 'Translation service must be switched off before its provider is removed'
    end
  end

  context 'with an unknown provider' do
    it_behaves_like 'raising an error', value: 'nope', message: 'Translation service is not supported'
  end

  context 'with a name of something else in the namespace' do
    it_behaves_like 'raising an error', value: 'base', message: 'Translation service is not supported'
  end

  context 'with a value that is no name' do
    it_behaves_like 'raising an error', value: { 'provider' => 'ai' }, message: 'Translation service is not supported'
  end

  context 'with the AI provider' do
    it_behaves_like 'not raising an error', value: 'ai'
  end

  context 'with DeepL' do
    context 'without its config' do
      it_behaves_like 'raising an error', value: 'deepl', message: 'Translation service configuration is incomplete'

      context 'when another process has stored the config since' do
        before { store_setting_behind_cache('content_translation_deepl_config', { 'api_key' => 'secret-key', 'tier' => 'free' }) }

        it_behaves_like 'not raising an error', value: 'deepl'
      end
    end

    context 'with its config' do
      before { Setting.set('content_translation_deepl_config', { 'api_key' => 'secret-key', 'tier' => 'free' }, validate: false) }

      it_behaves_like 'not raising an error', value: 'deepl'

      context 'when another process has removed the config since' do
        before { store_setting_behind_cache('content_translation_deepl_config', {}) }

        it_behaves_like 'raising an error', value: 'deepl', message: 'Translation service configuration is incomplete'
      end

      # The credentials were proven when the config was stored, so switching asks nothing.
      it 'does not reach DeepL' do
        Setting.set(setting_name, 'deepl')

        expect(WebMock).not_to have_requested(:any, %r{deepl\.com})
      end
    end
  end

  context 'with LibreTranslate' do
    context 'without its config' do
      it_behaves_like 'raising an error', value: 'libre_translate', message: 'Translation service configuration is incomplete'
    end

    context 'with the config of another provider only' do
      before { Setting.set('content_translation_deepl_config', { 'api_key' => 'secret-key', 'tier' => 'free' }, validate: false) }

      it_behaves_like 'raising an error', value: 'libre_translate', message: 'Translation service configuration is incomplete'
    end

    context 'with its config' do
      before { Setting.set('content_translation_libre_translate_config', { 'url' => 'https://translate.example.com' }, validate: false) }

      it_behaves_like 'not raising an error', value: 'libre_translate'
    end
  end
end
