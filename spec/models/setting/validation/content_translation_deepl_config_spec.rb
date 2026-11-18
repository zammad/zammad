# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::ContentTranslationDeepLConfig do
  let(:setting_name) { 'content_translation_deepl_config' }
  let(:endpoint)     { 'https://api-free.deepl.com/v2/translate' }
  let(:config)       { { 'api_key' => 'secret-key', 'tier' => 'free' } }

  before do
    stub_request(:post, endpoint)
      .to_return(status: 200, body: { translations: [{ text: 'Hallo' }] }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'stores a configuration DeepL answers for' do
    expect { Setting.set(setting_name, config) }.not_to raise_error
  end

  it 'stores a blank configuration' do
    expect { Setting.set(setting_name, {}) }.not_to raise_error
  end

  context 'when DeepL cannot be reached' do
    before { stub_request(:post, endpoint).to_timeout }

    it 'refuses it as unreachable' do
      expect { Setting.set(setting_name, config) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{cannot be reached})
    end
  end

  context 'when DeepL rejects the key' do
    before { stub_request(:post, endpoint).to_return(status: 403, body: { message: 'Authorization failed' }.to_json) }

    it 'refuses it as invalid credentials rather than as unreachable' do
      expect { Setting.set(setting_name, config) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{refused the configured credentials})
    end
  end

  context 'without the plan' do
    let(:config) { super().except('tier') }

    it 'refuses it as incomplete' do
      expect { Setting.set(setting_name, config) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{configuration is incomplete})
    end

    # The required keys are checked before the ping, so an incomplete config asks nothing.
    it 'sends the key nowhere' do
      suppress(ActiveRecord::RecordInvalid) { Setting.set(setting_name, config) }

      expect(WebMock).not_to have_requested(:post, endpoint)
    end
  end

  context 'with a provider key, as the combined config had' do
    let(:config) { super().merge('provider' => 'libre_translate') }

    it 'is still checked as DeepL' do
      Setting.set(setting_name, config)

      expect(WebMock).to have_requested(:post, endpoint)
    end
  end

  context 'when DeepL is the active provider' do
    before do
      Setting.set(setting_name, config)
      Setting.set('content_translation_provider', 'deepl')
    end

    it 'refuses to remove the configuration' do
      expect { Setting.set(setting_name, {}) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{active translation service cannot be removed})
    end

    it 'stores a changed configuration' do
      expect { Setting.set(setting_name, config.merge('api_key' => 'other-key')) }.not_to raise_error
    end

    context 'when another process has switched over to another provider since' do
      before { store_setting_behind_cache('content_translation_provider', 'ai') }

      it 'removes the configuration' do
        expect { Setting.set(setting_name, {}) }.not_to raise_error
      end
    end
  end

  context 'when another provider is active' do
    before do
      Setting.set(setting_name, config)
      Setting.set('content_translation_provider', 'ai')
    end

    it 'removes the configuration' do
      expect { Setting.set(setting_name, {}) }.not_to raise_error
    end

    context 'when another process has switched over to DeepL since' do
      before { store_setting_behind_cache('content_translation_provider', 'deepl') }

      it 'refuses to remove the configuration' do
        expect { Setting.set(setting_name, {}) }
          .to raise_error(ActiveRecord::RecordInvalid, %r{active translation service cannot be removed})
      end
    end
  end
end
