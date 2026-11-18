# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::ContentTranslationLibreTranslateConfig do
  let(:setting_name)       { 'content_translation_libre_translate_config' }
  let(:url)                { 'https://translate.example.com' }
  let(:languages_endpoint) { "#{url}/languages" }
  let(:translate_endpoint) { "#{url}/translate" }
  let(:config)             { { 'url' => url } }

  before do
    stub_hostname_resolution(url)
    stub_request(:get, languages_endpoint)
      .to_return(status: 200, body: [{ code: 'en' }, { code: 'de' }].to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:post, translate_endpoint)
      .to_return(status: 200, body: { translatedText: 'Zammad' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'stores a configuration the instance answers for' do
    expect { Setting.set(setting_name, config) }.not_to raise_error
  end

  it 'stores a blank configuration' do
    expect { Setting.set(setting_name, {}) }.not_to raise_error
  end

  context 'without the URL' do
    it 'refuses it as incomplete' do
      expect { Setting.set(setting_name, { 'api_key' => 'secret-key' }) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{configuration is incomplete})
    end
  end

  context 'when the instance cannot be reached' do
    before { stub_request(:get, languages_endpoint).to_timeout }

    it 'refuses it as unreachable' do
      expect { Setting.set(setting_name, config) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{cannot be reached})
    end
  end

  context 'with an API key' do
    let(:config) { super().merge('api_key' => 'secret-key') }

    it 'has the instance accept it' do
      Setting.set(setting_name, config)

      expect(WebMock).to have_requested(:post, translate_endpoint).with(body: hash_including('api_key' => 'secret-key'))
    end

    context 'when the instance rejects it' do
      before do
        stub_request(:post, translate_endpoint)
          .to_return(status: 403, body: { error: 'Invalid API key' }.to_json)
      end

      it 'refuses it as invalid credentials rather than as unreachable' do
        expect { Setting.set(setting_name, config) }
          .to raise_error(ActiveRecord::RecordInvalid, %r{refused the configured credentials})
      end
    end
  end

  context 'when LibreTranslate is the active provider' do
    before do
      Setting.set(setting_name, config)
      Setting.set('content_translation_provider', 'libre_translate')
    end

    it 'refuses to remove the configuration' do
      expect { Setting.set(setting_name, {}) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{active translation service cannot be removed})
    end
  end
end
