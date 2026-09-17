# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::ContentTranslation::TargetLocales do
  let(:german)  { Locale.find_by(locale: 'de-de') }
  let(:english) { Locale.find_by(locale: 'en-us') }

  before do
    setup_ai_provider
    setup_content_translation
  end

  it 'returns the active locales, sorted by name' do
    expect(described_class.execute).to eq(Locale.where(active: true).reorder(:name).to_a)
  end

  it 'leaves out inactive locales' do
    german.update!(active: false)

    expect(described_class.execute).not_to include(german)
  end

  context 'with a backend that supports a subset' do
    let(:backend) do
      Class.new(Service::ContentTranslation::Backend::Base) do
        def self.supported_locales(locales)
          locales.select { |locale| locale.locale == 'de-de' }
        end
      end
    end

    before { allow(Service::ContentTranslation::Backend).to receive(:configured).and_return(backend) }

    it 'returns only the locales the backend supports' do
      expect(described_class.execute).to eq([german])
    end
  end

  context 'with a backend that supports none of the active locales' do
    let(:backend) do
      Class.new(Service::ContentTranslation::Backend::Base) do
        def self.supported_locales(_locales)
          []
        end
      end
    end

    before { allow(Service::ContentTranslation::Backend).to receive(:configured).and_return(backend) }

    it 'returns no locales' do
      expect(described_class.execute).to be_empty
    end
  end

  context 'with LibreTranslate as the translation service' do
    let(:url) { 'https://translate.example.com' }

    before do
      # Without the validation, because saving the config runs the connection test.
      Setting.set('content_translation_service_config', { 'provider' => 'libre_translate', 'url' => url }, validate: false)

      stub_request(:get, "#{url}/languages")
        .to_return(status: 200, body: %w[en de].map { |code| { code: } }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    # Every region of a served language, e.g. British English along with American - and nothing else.
    def offered_languages
      described_class.execute.map { |locale| locale.locale.split('-').first }.uniq
    end

    it 'offers only the locales the instance serves' do
      expect(offered_languages).to contain_exactly('de', 'en')
    end

    it 'does not need an AI provider' do
      unset_ai_provider

      expect(offered_languages).to contain_exactly('de', 'en')
    end

    context 'when the instance cannot be reached' do
      before { stub_request(:get, "#{url}/languages").to_return(status: 503, body: 'Service Unavailable') }

      it 'raises an error' do
        expect { described_class.execute }
          .to raise_error(Service::ContentTranslation::Backend::Base::UnreachableError)
      end
    end
  end

  context 'when the AI provider is not configured' do
    before { unset_ai_provider }

    it 'raises an error' do
      expect { described_class.execute }
        .to raise_error(Service::CheckFeatureEnabled::FeatureDisabledError, 'AI provider is not configured.')
    end
  end

  context 'when the configured backend does not resolve' do
    before { allow(Service::ContentTranslation::Backend).to receive(:configured).and_return(nil) }

    it 'raises an error' do
      expect { described_class.execute }
        .to raise_error(Service::ContentTranslation::Base::UnknownBackendError)
    end
  end

  context 'when the translation service is switched off' do
    before { Setting.set('content_translation_service', false) }

    it 'raises an error' do
      expect { described_class.execute }
        .to raise_error(Service::CheckFeatureEnabled::FeatureDisabledError, 'No translation service is configured.')
    end
  end
end
