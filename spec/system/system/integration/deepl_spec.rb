# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/content_translation_integration_examples'

RSpec.describe 'Manage > Integration > DeepL', authenticated_as: :authenticate, type: :system do
  def authenticate
    true
  end

  it_behaves_like 'a content translation provider integration',
                  provider:       'deepl',
                  label:          'DeepL',
                  path:           'system/integration/deepl',
                  nav_key:        'IntegrationDeepL',
                  facility:       'DeepL',
                  config:         { 'api_key' => 'secret-key', 'tier' => 'free' },
                  other_provider: 'libre_translate',
                  other_label:    'LibreTranslate',
                  other_facility: 'LibreTranslate',
                  other_config:   { 'url' => 'https://translate.example.com' }

  describe 'the provider configuration' do
    before do
      # System specs run without WebMock, so saving - which runs the connection test - is answered
      # through UserAgent itself.
      allow(UserAgent).to receive(:post).and_return(UserAgent::Result.new(success: true, code: 200, data: { 'translations' => [{ 'text' => 'Hallo' }] }))

      visit 'system/integration/deepl'
    end

    it 'asks for the plan and the API key' do
      within :active_content do
        expect(page).to have_select('tier', options: ['-', 'Developer API (api-free.deepl.com)', 'Growth/Enterprise API (api.deepl.com)'])
        expect(page).to have_field('api_key')
      end
    end

    it 'stores a configuration DeepL answers for, without switching DeepL on' do
      within :active_content do
        select 'Developer API (api-free.deepl.com)', from: 'tier'
        fill_in 'api_key', with: 'secret-key'
        click_on 'Save'
      end

      wait_for_setting('content_translation_deepl_config', 'secret-key', key: 'api_key')
      expect(Setting.get('content_translation_provider')).to eq('')
    end

    context 'with a stored configuration' do
      before do
        Setting.set('content_translation_deepl_config', { 'api_key' => 'secret-key', 'tier' => 'free' }, validate: false)
        refresh
      end

      it 'shows the API key masked' do
        within :active_content do
          expect(page).to have_select('tier', selected: 'Developer API (api-free.deepl.com)')
          expect(page).to have_no_field('api_key', with: 'secret-key')
        end
      end
    end
  end
end
