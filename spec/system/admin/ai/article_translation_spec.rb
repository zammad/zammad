# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > AI > Article Translation', authenticated_as: :authenticate, type: :system do
  let(:switch_name)  { 'content-translation-ai' }
  let(:deepl_config) { { 'api_key' => 'secret-key', 'tier' => 'free' } }

  def authenticate
    true
  end

  def activate(provider)
    Setting.set('content_translation_provider', provider)
    Setting.set('content_translation_service', true)
    Setting.set('content_translation_ticket_article', true)
  end

  context 'with the AI translation permission deactivated' do
    def authenticate
      Permission.find_by(name: 'admin.ai_assistance_translation').update!(active: false)

      super
    end

    it 'is not in the AI menu' do
      visit '#ai/ticket_summary'

      # Another entry first, so the absence is not checked before the menu has rendered.
      expect(page).to have_link(href: '#ai/ticket_summary')
      expect(page).to have_no_link(href: '#ai/article_translation')
    end

    # The admin area falls back to its first entry for a page the user may not open.
    it 'does not open the page on a direct visit' do
      visit '#ai/article_translation'

      within :active_content do
        expect(page).to have_css('h1', text: 'Users')
        expect(page).to have_no_css('h1', text: 'Article Translation')
      end
    end
  end

  context 'when opened from the AI menu' do
    it 'shows the page with its switch off' do
      visit '#ai/ticket_summary'

      click_on 'Article Translation'

      within :active_content do
        expect(page).to have_css('h1', text: 'Article Translation')
        expect(page).to have_text('This service allows agents to translate articles to their configured UI language or other languages of their choice.')
        expect(page).to have_button('Provider')
        check_switch_field_value(switch_name, false)
      end
    end
  end

  describe 'the switch' do
    before do
      visit '#ai/article_translation'
    end

    it 'switches AI translation on for agents, and off again', :aggregate_failures do
      within :active_content do
        set_switch_field_value(switch_name, true)
      end

      wait_for_setting('content_translation_ticket_article', true)
      expect(Setting.get('content_translation_provider')).to eq('ai')
      expect(Setting.get('content_translation_service')).to be(true)

      within :active_content do
        set_switch_field_value(switch_name, false)
      end

      wait_for_setting('content_translation_provider', '')
      expect(Setting.get('content_translation_service')).to be(false)
      expect(Setting.get('content_translation_ticket_article')).to be(false)
    end

    it 'warns while the AI provider is switched off' do
      within :active_content do
        expect(page).to have_no_css('.js-missingProviderAlert:not(.hide)')

        set_switch_field_value(switch_name, true)

        expect(page).to have_css('.js-missingProviderAlert:not(.hide)', text: 'The AI provider configuration is disabled.')
      end
    end
  end

  context 'with AI active while the AI provider is switched off' do
    before do
      activate('ai')

      visit '#ai/article_translation'
    end

    # A push sent before the session is logged in on the server is lost. Unlike
    # wait_for_authenticated_session this accepts the long-polling fallback as well.
    def wait_for_session_login
      wait.until { Sessions.list.values.any? { |session| session.dig(:user, 'id').present? } }
    end

    it 'follows a switch to another provider made elsewhere' do
      within :active_content do
        check_switch_field_value(switch_name, true)
        expect(page).to have_css('.js-missingProviderAlert:not(.hide)')
      end

      wait_for_session_login
      Setting.set('content_translation_deepl_config', deepl_config, validate: false)
      Setting.set('content_translation_provider', 'deepl')

      within :active_content do
        check_switch_field_value(switch_name, false)
        expect(page).to have_no_css('.js-missingProviderAlert:not(.hide)')
      end
    end
  end

  context 'with DeepL active' do
    before do
      Setting.set('content_translation_deepl_config', deepl_config, validate: false)
      activate('deepl')

      visit '#ai/article_translation'

      within :active_content do
        set_switch_field_value(switch_name, true)
      end
    end

    it 'switches over on confirmation and keeps the DeepL configuration', :aggregate_failures do
      in_modal do
        expect(page).to have_text('DeepL is the active translation provider. Turning on AI switches it off. Its configuration and logs are kept.')

        click_on 'Switch provider'
      end

      wait_for_setting('content_translation_provider', 'ai')
      expect(Setting.get('content_translation_deepl_config')).to eq(deepl_config)
      expect(Setting.get('content_translation_service')).to be(true)
    end

    it 'leaves DeepL active on cancel' do
      in_modal do
        click_on 'Cancel & Go Back'
      end

      within :active_content do
        check_switch_field_value(switch_name, false)
      end

      expect(Setting.get('content_translation_provider')).to eq('deepl')
    end
  end

  describe 'the shared article settings' do
    it 'persists the switch for translating all articles at once' do
      visit '#ai/article_translation'

      within :active_content do
        set_switch_field_value('content_translation_ticket_article_auto', true)
      end

      wait_for_setting('content_translation_ticket_article_auto', true)
    end
  end

  describe 'the provider button' do
    it 'opens the provider of the translation feature' do
      visit '#ai/article_translation'

      within :active_content do
        click_on 'Provider'
      end

      in_modal do
        expect(page).to have_select('provider_connection_id')
      end
    end
  end

  context 'with a delegated administrator holding the AI translation permission only' do
    let(:role)            { create(:role, permission_names: %w[admin.ai_assistance_translation]) }
    let(:delegated_admin) { create(:agent, roles: [role]) }

    def authenticate
      super

      delegated_admin
    end

    it 'switches AI translation on and changes the shared settings', :aggregate_failures do
      visit '#ai/article_translation'

      within :active_content do
        set_switch_field_value(switch_name, true)
      end

      wait_for_setting('content_translation_ticket_article', true)
      expect(Setting.get('content_translation_provider')).to eq('ai')

      within :active_content do
        set_switch_field_value('content_translation_ticket_article_auto', true)
      end

      wait_for_setting('content_translation_ticket_article_auto', true)
    end

    it 'offers no provider button, which needs the AI provider permission' do
      visit '#ai/article_translation'

      within :active_content do
        expect(page).to have_css('h1', text: 'Article Translation')
        expect(page).to have_no_button('Provider')
      end
    end
  end
end
