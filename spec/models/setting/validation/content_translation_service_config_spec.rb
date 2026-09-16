# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::ContentTranslationServiceConfig do
  let(:setting_name) { 'content_translation_service_config' }

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

  context 'with a blank config' do
    it_behaves_like 'not raising an error', value: {}
  end

  context 'with a config that names no service' do
    it_behaves_like 'raising an error', value: { 'token' => 'secret' }, message: 'Translation service is missing'
  end

  context 'with an unknown service' do
    it_behaves_like 'raising an error', value: { 'provider' => 'nope' }, message: 'Translation service is not supported'
  end

  context 'with the AI service' do
    it_behaves_like 'not raising an error', value: { 'provider' => 'ai' }
  end

  context 'with the LibreTranslate service' do
    let(:url)                { 'https://translate.example.com' }
    let(:languages_endpoint) { "#{url}/languages" }
    let(:translate_endpoint) { "#{url}/translate" }
    let(:config)             { { 'provider' => 'libre_translate', 'url' => url } }

    before do
      stub_request(:get, languages_endpoint)
        .to_return(status: 200, body: [{ code: 'en' }, { code: 'de' }].to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, translate_endpoint)
        .to_return(status: 200, body: { translatedText: 'Zammad' }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'stores a configuration the instance answers for' do
      expect { Setting.set(setting_name, config) }.not_to raise_error
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
  end

  context 'with a service that needs credentials' do
    let(:backend) do
      Class.new(Service::ContentTranslation::Backend::Base) do
        def self.backend_name = 'keyed'

        def self.required_config_keys = %w[token]
      end
    end

    before { stub_const('Service::ContentTranslation::Backend::Keyed', backend) }

    it_behaves_like 'raising an error', value: { 'provider' => 'keyed' }, message: 'Translation service configuration is incomplete'
    it_behaves_like 'not raising an error', value: { 'provider' => 'keyed', 'token' => 'secret' }
  end
end
