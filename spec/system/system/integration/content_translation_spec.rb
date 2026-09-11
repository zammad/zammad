# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > Content translation', type: :system do
  let(:language_detection_warning) { 'The article language detection is disabled.' }

  # A push sent before the session is logged in on the server is lost. Unlike
  # wait_for_authenticated_session this accepts the long-polling fallback as well.
  def wait_for_session_login
    wait.until { Sessions.list.values.any? { |session| session.dig(:user, 'id').present? } }
  end

  def open_ticket_articles_tab
    visit 'system/integration/content_translation'

    within :active_content do
      find('.nav-tabs a[href="#ticket-articles"]').click
    end
  end

  context 'when listed on the integrations page' do
    before do
      visit '#system/integration'
    end

    it 'is listed and opens without a header switch' do
      expect(page).to have_css('tr[data-key=IntegrationContentTranslation]')

      click_on 'Translation services'

      within :active_content do
        expect(page).to have_text('This service allows agents to translate articles to their configured UI language or other languages of their choice.')
        expect(page).to have_no_css('.page-header .zammad-switch')
      end
    end
  end

  context 'with the AI provider switched off' do
    before do
      visit 'system/integration/content_translation'
    end

    it 'offers the service and warns about the switched-off provider' do
      within :active_content do
        expect(page).to have_select('provider', options: ['-', 'AI provider'])
        expect(page).to have_css('.js-missingProviderAlert', text: 'The provider configuration is disabled.')
      end
    end
  end

  context 'with a configured service whose AI provider was switched off' do
    before do
      Setting.set('content_translation_service_config', { 'provider' => 'ai' })
      Setting.set('content_translation_service', true)

      visit 'system/integration/content_translation'
    end

    it 'keeps the service selected and still offers the provider configuration' do
      within :active_content do
        expect(page).to have_select('provider', selected: 'AI provider')
        expect(page).to have_select('ai_provider_connection_id', options: ['Default (none)'])
        expect(page).to have_css('.js-missingProviderAlert', text: 'The provider configuration is disabled.')
      end
    end
  end

  # An installation without AI at all deactivates the permission, which is what removes the service.
  context 'without the AI provider permission' do
    before do
      Permission.find_by(name: 'admin.ai_provider').update!(active: false)
      Setting.set('content_translation_service_config', { 'provider' => 'ai' })
      Setting.set('content_translation_service', true)

      visit 'system/integration/content_translation'
    end

    it 'offers no service and no warning' do
      within :active_content do
        expect(page).to have_select('provider', options: ['-'], selected: '-')
        expect(page).to have_no_css('.js-missingProviderAlert')
      end
    end
  end

  context 'with a configured AI provider', authenticated_as: :authenticate do
    def authenticate
      create(:ai_provider_connection)
      Setting.set('ai_provider', true)

      true
    end

    before do
      visit 'system/integration/content_translation'
    end

    it 'offers the AI provider without a warning' do
      within :active_content do
        expect(page).to have_select('provider', options: ['-', 'AI provider'])
        expect(page).to have_no_css('.js-missingProviderAlert')
      end
    end

    it 'stores the selected service' do
      within :active_content do
        select 'AI provider', from: 'provider'
        click_on 'Save'
      end

      wait_for_setting('content_translation_service', true)
      expect(Setting.get('content_translation_service_config')).to eq({ 'provider' => 'ai' })
    end

    context 'with the AI service stored' do
      def authenticate
        super

        Setting.set('content_translation_service_config', { 'provider' => 'ai' })
        Setting.set('content_translation_service', true)

        true
      end

      it 'removes the service and switches the flag off' do
        within :active_content do
          select '-', from: 'provider'
          click_on 'Save'
        end

        wait_for_setting('content_translation_service', false)
        expect(Setting.get('content_translation_service_config')).to eq({})
      end
    end

    context 'with the AI provider selected' do
      let(:default_connection) { create(:ai_provider_connection, :default_chat, name: 'Default connection') }
      let(:other_connection)   { create(:ai_provider_connection, name: 'Other connection') }

      def authenticate
        default_connection
        other_connection
        Setting.set('ai_provider', true)

        true
      end

      def routed_connection_id
        AI::FeatureProvider.find_by(identifier: 'translate')&.provider_connection_id
      end

      before do
        within :active_content do
          select 'AI provider', from: 'provider'
        end
      end

      it 'names the connection field for assistive technology' do
        within :active_content do
          select_id = find('select[name=ai_provider_connection_id]')[:id]

          expect(page).to have_css("label[for='#{select_id}']", text: 'Provider', visible: :all)
        end
      end

      it 'offers the connections with the default one named' do
        within :active_content do
          expect(page).to have_select('ai_provider_connection_id', options: ['Default (Default connection)', 'Default connection', 'Other connection'])
        end
      end

      it 'routes the translation feature to the selected connection' do
        within :active_content do
          select 'Other connection', from: 'ai_provider_connection_id'
          click_on 'Save'
        end

        wait.until { routed_connection_id == other_connection.id }
      end

      it 'offers no extra option after the service was switched again' do
        within :active_content do
          select 'Other connection', from: 'ai_provider_connection_id'
          select '-', from: 'provider'
          select 'AI provider', from: 'provider'

          expect(page).to have_select('ai_provider_connection_id', options: ['Default (Default connection)', 'Default connection', 'Other connection'], selected: 'Other connection')
        end
      end

      context 'with the feature already routed to a connection' do
        def authenticate
          super

          create(:ai_feature_provider, identifier: 'translate', provider_connection: other_connection)

          true
        end

        it 'shows the routed connection' do
          within :active_content do
            expect(page).to have_select('ai_provider_connection_id', selected: 'Other connection')
          end
        end

        it 'removes the routing row when the default entry is picked back' do
          within :active_content do
            select 'Default (Default connection)', from: 'ai_provider_connection_id'
            click_on 'Save'
          end

          wait.until { AI::FeatureProvider.find_by(identifier: 'translate').nil? }
        end

        # A row removed elsewhere leaves this form holding its id, so the save runs into a real 404.
        # A notification is awaited first, to tell "not saved yet" apart from "never saved".
        it 'saves no setting when the row could not be written' do
          AI::FeatureProvider.destroy_all

          within :active_content do
            select 'Default connection', from: 'ai_provider_connection_id'
            click_on 'Save'
          end

          expect(page).to have_css('.noty_message', visible: :all)
          expect(Setting.get('content_translation_service')).to be false
          expect(Setting.get('content_translation_service_config')).to eq({})
        end
      end

      # Both APIs behind the row require admin.ai_provider, so it is not offered without it.
      context 'with a delegated administrator without AI provider permission' do
        let(:role)            { create(:role, permission_names: %w[admin.integration]) }
        let(:delegated_admin) { create(:agent, roles: [role]) }

        def authenticate
          super

          delegated_admin
        end

        it 'offers the service without the AI provider row' do
          within :active_content do
            expect(page).to have_select('provider', selected: 'AI provider')
            expect(page).to have_no_select('ai_provider_connection_id')
          end
        end
      end
    end
  end

  context 'without article language detection' do
    it 'warns on the ticket articles tab only' do
      visit 'system/integration/content_translation'

      within :active_content do
        expect(page).to have_select('provider')
        expect(page).to have_no_text(language_detection_warning)

        find('.nav-tabs a[href="#ticket-articles"]').click

        expect(page).to have_css('.js-languageDetectionAlert', text: language_detection_warning)
      end
    end
  end

  context 'with article language detection', authenticated_as: :authenticate do
    def authenticate
      Setting.set('language_detection_article', 'cld')

      true
    end

    before do
      open_ticket_articles_tab
    end

    it 'shows no warning' do
      within :active_content do
        expect(page).to have_css('.js-ticketArticleSetting')
        expect(page).to have_no_text(language_detection_warning)
      end
    end
  end

  describe 'Ticket Articles tab' do
    let(:role_ids_selector) { "[data-attribute-name='content_translation_ticket_article_auto_role_ids']" }

    def select_role(name)
      click "#{role_ids_selector} .columnSelect-column--sidebar .columnSelect-option", exact_text: name
    end

    def deselect_role(name)
      click "#{role_ids_selector} .columnSelect-column--selected .columnSelect-option", exact_text: name
    end

    it 'persists the article translation switch' do
      open_ticket_articles_tab

      within :active_content do
        check_switch_field_value('content_translation_ticket_article', false)
        set_switch_field_value('content_translation_ticket_article', true)
      end

      wait_for_setting('content_translation_ticket_article', true)

      refresh
      open_ticket_articles_tab

      within :active_content do
        check_switch_field_value('content_translation_ticket_article', true)
      end
    end

    it 'persists the auto translation switch' do
      open_ticket_articles_tab

      within :active_content do
        check_switch_field_value('content_translation_ticket_article_auto', false)
        set_switch_field_value('content_translation_ticket_article_auto', true)
      end

      wait_for_setting('content_translation_ticket_article_auto', true)

      refresh
      open_ticket_articles_tab

      within :active_content do
        check_switch_field_value('content_translation_ticket_article_auto', true)
      end
    end

    it 'persists the roles selection and clears it again' do
      open_ticket_articles_tab

      within :active_content do
        select_role('Agent')
        click_on 'Submit'
      end

      wait_for_setting('content_translation_ticket_article_auto_role_ids', [Role.lookup(name: 'Agent').id.to_s])

      refresh
      open_ticket_articles_tab

      within :active_content do
        expect(page).to have_css("#{role_ids_selector} .columnSelect-column--selected .columnSelect-option", exact_text: 'Agent')

        deselect_role('Agent')
        click_on 'Submit'
      end

      wait_for_setting('content_translation_ticket_article_auto_role_ids', [])
    end

    it 'keeps an unsaved roles selection while a switch is toggled' do
      open_ticket_articles_tab

      within :active_content do
        select_role('Agent')
        set_switch_field_value('content_translation_ticket_article', true)
      end

      wait_for_setting('content_translation_ticket_article', true)

      # A change from elsewhere arrives as the same push; the switch following it proves it was handled.
      wait_for_session_login
      Setting.set('content_translation_ticket_article_auto', true)

      within :active_content do
        check_switch_field_value('content_translation_ticket_article_auto', true)
        expect(page).to have_css("#{role_ids_selector} .columnSelect-column--selected .columnSelect-option", exact_text: 'Agent')
      end

      expect(Setting.get('content_translation_ticket_article_auto_role_ids')).to eq([])
    end

    it 'shows a roles selection saved elsewhere' do
      open_ticket_articles_tab

      within :active_content do
        expect(page).to have_css("#{role_ids_selector} .columnSelect-column--sidebar .columnSelect-option", exact_text: 'Agent')
      end

      wait_for_session_login
      Setting.set('content_translation_ticket_article_auto_role_ids', [Role.lookup(name: 'Agent').id.to_s])

      within :active_content do
        expect(page).to have_css("#{role_ids_selector} .columnSelect-column--selected .columnSelect-option", exact_text: 'Agent')
      end
    end
  end

  describe 'Logs tab' do
    let(:ai_hint) { 'You can find relevant AI provider logs under AI > Feedback & Logs.' }

    def open_logs_tab
      visit 'system/integration/content_translation'

      within :active_content do
        find('.nav-tabs a[href="#logs"]').click
      end
    end

    it 'shows the empty state without entries' do
      open_logs_tab

      within :active_content do
        expect(page).to have_css('h2', text: 'Recent Logs', count: 1)
        # Table headers are uppercased by CSS, and Capybara matches the rendered text.
        expect(page).to have_text('NO ENTRIES')
      end
    end

    it 'lists an entry and opens its detail modal' do
      http_log = create(:http_log, facility: 'content_translation', url: 'https://example.com/translate')

      open_logs_tab

      within :active_content do
        find("tr[data-id='#{http_log.id}']").click
      end

      in_modal do
        expect(page).to have_text('HTTP Log')
          .and have_text('https://example.com/translate')
      end
    end

    it 'shows no hint without a configured service' do
      open_logs_tab

      within :active_content do
        expect(page).to have_text('NO ENTRIES')
        expect(page).to have_no_text(ai_hint)
      end
    end

    context 'with AI as the configured service', authenticated_as: :authenticate do
      def authenticate
        Setting.set('content_translation_service_config', { 'provider' => 'ai' })

        true
      end

      # There will never be a translation entry while AI is used, because those requests are logged
      # under the AI::Provider facility.
      it 'points at the screen that has the AI logs instead of an empty log' do
        open_logs_tab

        within :active_content do
          expect(page).to have_css('h2', text: 'Recent Logs')
          expect(page).to have_text(ai_hint)
          expect(page).to have_css('.js-aiHint a[href="#ai/feedback_logs"]')
          expect(page).to have_no_text('NO ENTRIES')
        end
      end

      it 'shows the log again when the service is switched off' do
        open_logs_tab

        within :active_content do
          expect(page).to have_text(ai_hint)

          find('.nav-tabs a[href="#provider-settings"]').click
          select '-', from: 'provider'
          click_on 'Save'

          find('.nav-tabs a[href="#logs"]').click

          expect(page).to have_text('NO ENTRIES')
          expect(page).to have_no_text(ai_hint)
        end
      end

      context 'with a delegated administrator without AI logs permission' do
        let(:role)            { create(:role, permission_names: %w[admin.integration]) }
        let(:delegated_admin) { create(:agent, roles: [role]) }

        def authenticate
          Setting.set('content_translation_service_config', { 'provider' => 'ai' })

          delegated_admin
        end

        # Following the link would only bounce off permissionCheckRedirect, so it is not offered.
        it 'names the screen without linking it' do
          open_logs_tab

          within :active_content do
            expect(page).to have_text(ai_hint)
            expect(page).to have_no_css('.js-aiHint a')
            expect(page).to have_no_text('NO ENTRIES')
          end
        end
      end
    end
  end
end
