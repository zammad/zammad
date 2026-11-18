# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/content_translation_integration_examples'

RSpec.describe 'Manage > Integration > LibreTranslate', authenticated_as: :authenticate, type: :system do
  def authenticate
    true
  end

  it_behaves_like 'a content translation provider integration',
                  provider:       'libre_translate',
                  label:          'LibreTranslate',
                  path:           'system/integration/libre_translate',
                  nav_key:        'IntegrationLibreTranslate',
                  facility:       'LibreTranslate',
                  config:         { 'url' => 'https://translate.example.com' },
                  other_provider: 'deepl',
                  other_label:    'DeepL',
                  other_facility: 'DeepL',
                  other_config:   { 'api_key' => 'secret-key', 'tier' => 'free' }

  describe 'the provider configuration' do
    let(:url) { 'https://translate.example.com' }

    def configure(api_key: nil)
      within :active_content do
        fill_in 'url', with: url
        fill_in 'api_key', with: api_key if api_key
        click_on 'Save'
      end
    end

    before do
      # System specs run without WebMock, so saving - which runs the connection test - is answered
      # through UserAgent itself.
      allow(UserAgent).to receive_messages(
        get:  UserAgent::Result.new(success: true, code: 200, data: [{ 'code' => 'en' }, { 'code' => 'de' }]),
        post: UserAgent::Result.new(success: true, code: 200, data: { 'translatedText' => 'Zammad' }),
      )

      visit 'system/integration/libre_translate'
    end

    it 'asks for the server URL and the API key' do
      within :active_content do
        expect(page).to have_field('url')
        expect(page).to have_field('api_key')
      end
    end

    it 'stores a configuration the instance answers for, without switching LibreTranslate on' do
      configure

      wait_for_setting('content_translation_libre_translate_config', url, key: 'url')
      expect(Setting.get('content_translation_provider')).to eq('')
    end

    it 'stores an API key with it' do
      configure(api_key: 'secret-key')

      wait_for_setting('content_translation_libre_translate_config', 'secret-key', key: 'api_key')
    end

    context 'when the instance cannot be reached' do
      before { allow(UserAgent).to receive(:get).and_return(UserAgent::Result.new(success: false, code: 0)) }

      it 'refuses the configuration with the reason instead of storing it' do
        configure

        expect(page).to have_text('The translation service cannot be reached.')
        expect(Setting.get('content_translation_libre_translate_config')).to eq({})
      end
    end

    context 'with a stored configuration' do
      before do
        Setting.set('content_translation_libre_translate_config', { 'url' => url, 'api_key' => 'secret-key' }, validate: false)
        refresh
      end

      it 'shows the URL and the API key masked' do
        within :active_content do
          expect(page).to have_field('url', with: url)
          expect(page).to have_no_field('api_key', with: 'secret-key')
        end
      end
    end
  end
end
