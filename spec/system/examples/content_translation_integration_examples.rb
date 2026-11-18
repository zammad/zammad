# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Covers what every translation provider page shares: the switch with its warning before
# another provider is replaced, the article settings, the logs and the feedback of that provider.
# The including spec defines `authenticate` and covers the configuration form, which differs per
# provider. `other_provider` is any second provider with a valid configuration.
RSpec.shared_examples 'a content translation provider integration' do |provider:, label:, path:, nav_key:, facility:, config:, other_provider:, other_label:, other_facility:, other_config:|
  let(:switch_name)                { "content-translation-#{provider}" }
  let(:config_setting)             { "content_translation_#{provider}_config" }
  let(:other_config_setting)       { "content_translation_#{other_provider}_config" }
  let(:language_detection_warning) { 'The article language detection is disabled.' }

  # A push sent before the session is logged in on the server is lost. Unlike
  # wait_for_authenticated_session this accepts the long-polling fallback as well.
  def wait_for_session_login
    wait.until { Sessions.list.values.any? { |session| session.dig(:user, 'id').present? } }
  end

  def open_tab(path, target)
    visit path

    within :active_content do
      find(".nav-tabs a[href='##{target}']").click
    end
  end

  def activate(provider)
    Setting.set('content_translation_provider', provider)
    Setting.set('content_translation_service', true)
    Setting.set('content_translation_ticket_article', true)
  end

  context 'when listed on the integrations page' do
    it 'opens the page of the provider' do
      visit '#system/integration'

      click_on label

      within :active_content do
        expect(page).to have_text('This service allows agents to translate articles to their configured UI language or other languages of their choice.')
        check_switch_field_value(switch_name, false)
      end
    end
  end

  describe 'the switch' do
    context 'without a configuration' do
      it 'refuses to switch the provider on and turns back' do
        visit path

        within :active_content do
          set_switch_field_value(switch_name, true)
        end

        expect(page).to have_text('Translation service configuration is incomplete')

        within :active_content do
          check_switch_field_value(switch_name, false)
        end

        expect(Setting.get('content_translation_provider')).to eq('')
      end
    end

    context 'with a configuration' do
      before do
        Setting.set(config_setting, config, validate: false)

        visit path
      end

      it 'switches the provider on for agents, and off again', :aggregate_failures do
        within :active_content do
          set_switch_field_value(switch_name, true)
        end

        wait_for_setting('content_translation_ticket_article', true)
        expect(Setting.get('content_translation_provider')).to eq(provider)
        expect(Setting.get('content_translation_service')).to be(true)

        within :active_content do
          set_switch_field_value(switch_name, false)
        end

        wait_for_setting('content_translation_provider', '')
        expect(Setting.get('content_translation_service')).to be(false)
        expect(Setting.get('content_translation_ticket_article')).to be(false)
        expect(Setting.get(config_setting)).to eq(config)
      end

      it 'is listed as active once switched on' do
        within :active_content do
          set_switch_field_value(switch_name, true)
        end

        wait_for_setting('content_translation_provider', provider)

        visit '#system/integration'

        expect(page).to have_css("tr[data-key=#{nav_key}] .icon-status.ok")
      end
    end

    context 'when only the provider is stored, as a single setting written through the API leaves it' do
      before do
        Setting.set(config_setting, config, validate: false)
        Setting.set(other_config_setting, other_config, validate: false)
      end

      it 'shows the provider as off and completes the switch on retry', :aggregate_failures do
        Setting.set('content_translation_provider', provider)

        visit path

        within :active_content do
          check_switch_field_value(switch_name, false)
          set_switch_field_value(switch_name, true)
        end

        wait_for_setting('content_translation_ticket_article', true)
        expect(Setting.get('content_translation_service')).to be(true)

        within :active_content do
          check_switch_field_value(switch_name, true)
        end
      end

      it 'replaces another provider whose flags are off without a warning' do
        Setting.set('content_translation_provider', other_provider)

        visit path

        within :active_content do
          set_switch_field_value(switch_name, true)
        end

        wait_for_setting('content_translation_ticket_article', true)
        expect(Setting.get('content_translation_provider')).to eq(provider)
      end
    end

    context 'with another provider active' do
      before do
        Setting.set(config_setting, config, validate: false)
        Setting.set(other_config_setting, other_config, validate: false)
        activate(other_provider)
        Setting.set('content_translation_ticket_article_auto', true)

        visit path

        within :active_content do
          set_switch_field_value(switch_name, true)
        end
      end

      it 'warns that the other provider is switched off' do
        in_modal do
          expect(page).to have_text("#{other_label} is the active translation provider. Turning on #{label} switches it off. Its configuration and logs are kept.")
        end
      end

      it 'switches over on confirmation and keeps the other configuration and the shared settings', :aggregate_failures do
        in_modal do
          click_on 'Switch provider'
        end

        wait_for_setting('content_translation_provider', provider)
        expect(Setting.get(other_config_setting)).to eq(other_config)
        expect(Setting.get('content_translation_service')).to be(true)
        expect(Setting.get('content_translation_ticket_article_auto')).to be(true)

        within :active_content do
          check_switch_field_value(switch_name, true)
        end
      end

      it 'leaves the other provider active on cancel', :aggregate_failures do
        in_modal do
          click_on 'Cancel & Go Back'
        end

        within :active_content do
          check_switch_field_value(switch_name, false)
        end

        expect(Setting.get('content_translation_provider')).to eq(other_provider)
      end

      it 'leaves the other provider active when the dialog is closed', :aggregate_failures do
        modal_ready
        send_keys(:escape)

        within :active_content do
          check_switch_field_value(switch_name, false)
        end

        expect(Setting.get('content_translation_provider')).to eq(other_provider)
      end
    end

    context 'when another admin switches over to another provider' do
      before do
        Setting.set(config_setting, config, validate: false)
        activate(provider)

        visit path
      end

      it 'turns the switch off' do
        within :active_content do
          check_switch_field_value(switch_name, true)
        end

        wait_for_session_login
        Setting.set('content_translation_provider', 'ai')

        within :active_content do
          check_switch_field_value(switch_name, false)
        end
      end
    end

    context 'with a delegated administrator holding the integration permission only' do
      let(:role)            { create(:role, permission_names: %w[admin.integration]) }
      let(:delegated_admin) { create(:agent, roles: [role]) }

      def authenticate
        super

        delegated_admin
      end

      it 'switches the provider on' do
        Setting.set(config_setting, config, validate: false)

        visit path

        within :active_content do
          set_switch_field_value(switch_name, true)
        end

        wait_for_setting('content_translation_ticket_article', true)
        expect(Setting.get('content_translation_provider')).to eq(provider)
      end
    end
  end

  describe 'the shared article settings' do
    let(:role_ids_selector) { "[data-attribute-name='content_translation_ticket_article_auto_role_ids']" }

    def select_role(name)
      click "#{role_ids_selector} .columnSelect-column--sidebar .columnSelect-option", exact_text: name
    end

    def deselect_role(name)
      click "#{role_ids_selector} .columnSelect-column--selected .columnSelect-option", exact_text: name
    end

    it 'persists the switch for translating all articles at once' do
      visit path

      within :active_content do
        check_switch_field_value('content_translation_ticket_article_auto', false)
        set_switch_field_value('content_translation_ticket_article_auto', true)
      end

      wait_for_setting('content_translation_ticket_article_auto', true)

      refresh

      within :active_content do
        check_switch_field_value('content_translation_ticket_article_auto', true)
      end
    end

    it 'persists the roles selection and clears it again' do
      visit path

      within :active_content do
        select_role('Agent')
        click_on 'Submit'
      end

      wait_for_setting('content_translation_ticket_article_auto_role_ids', [Role.lookup(name: 'Agent').id.to_s])

      refresh

      within :active_content do
        expect(page).to have_css("#{role_ids_selector} .columnSelect-column--selected .columnSelect-option", exact_text: 'Agent')

        deselect_role('Agent')
        click_on 'Submit'
      end

      wait_for_setting('content_translation_ticket_article_auto_role_ids', [])
    end

    it 'keeps an unsaved roles selection while the switch follows a change from elsewhere' do
      visit path

      within :active_content do
        select_role('Agent')
      end

      wait_for_session_login
      Setting.set('content_translation_ticket_article_auto', true)

      within :active_content do
        check_switch_field_value('content_translation_ticket_article_auto', true)
        expect(page).to have_css("#{role_ids_selector} .columnSelect-column--selected .columnSelect-option", exact_text: 'Agent')
      end

      expect(Setting.get('content_translation_ticket_article_auto_role_ids')).to eq([])
    end

    context 'without article language detection' do
      it 'warns and links the ticket settings' do
        visit path

        within :active_content do
          expect(page).to have_css('.js-languageDetectionAlert', text: language_detection_warning)
          expect(page).to have_css('.js-languageDetectionAlert a[href="#settings/ticket"]')
        end
      end
    end

    context 'with article language detection' do
      def authenticate
        Setting.set('language_detection_article', 'cld')

        super
      end

      it 'shows no warning' do
        visit path

        within :active_content do
          expect(page).to have_css('.js-ticketArticleAutoSetting')
          expect(page).to have_no_text(language_detection_warning)
        end
      end
    end

    context 'with a delegated administrator without the ticket settings permission' do
      let(:role)            { create(:role, permission_names: %w[admin.integration]) }
      let(:delegated_admin) { create(:agent, roles: [role]) }

      def authenticate
        super

        delegated_admin
      end

      # Following the link would only bounce off permissionCheckRedirect, so it is not offered.
      it 'points to an administrator instead of linking the ticket settings' do
        visit path

        within :active_content do
          expect(page).to have_css('.js-languageDetectionAlert', text: 'ask an administrator with access to the ticket settings')
          expect(page).to have_no_css('.js-languageDetectionAlert a')
        end
      end
    end
  end

  describe 'the logs tab' do
    it "lists only the requests to #{label}" do
      own_log   = create(:http_log, facility: facility, url: 'https://translate.example.com/own')
      other_log = create(:http_log, facility: other_facility, url: 'https://translate.example.com/other')

      open_tab(path, 'logs')

      within :active_content do
        expect(page).to have_css("tr[data-id='#{own_log.id}']")
        expect(page).to have_no_css("tr[data-id='#{other_log.id}']")
      end
    end

    it 'shows the empty state without entries' do
      open_tab(path, 'logs')

      within :active_content do
        # Table headers are uppercased by CSS, and Capybara matches the rendered text.
        expect(page).to have_text('NO ENTRIES')
      end
    end
  end

  describe 'the feedback tab' do
    it "downloads the feedback on #{label} translations only" do
      own_run = create(:ai_analytics_run, identifier: Service::ContentTranslation::StoredTranslation::IDENTIFIER, ai_service_name: provider)
      create(:ai_analytics_run, identifier: Service::ContentTranslation::StoredTranslation::IDENTIFIER, ai_service_name: other_provider)
      create(:ai_analytics_run, identifier: 'ticket_summarize')

      reported_scope = nil
      allow(Service::AI::Analytics::GenerateReport::WithUsages).to receive(:new).and_wrap_original do |original, **args|
        reported_scope = args[:scope]
        original.call(**args)
      end

      open_tab(path, 'feedback')

      within :active_content do
        expect(page).to have_text('Download feedback from agents on translations.')

        click_on 'Download Feedback'
      end

      wait.until { reported_scope }
      expect(reported_scope).to contain_exactly(own_run)
    end

    context 'with a delegated administrator without AI logs permission' do
      let(:role)            { create(:role, permission_names: %w[admin.integration]) }
      let(:delegated_admin) { create(:agent, roles: [role]) }

      def authenticate
        super

        delegated_admin
      end

      it 'offers no feedback tab' do
        visit path

        within :active_content do
          expect(page).to have_css('.nav-tabs a[href="#logs"]')
          expect(page).to have_no_css('.nav-tabs a[href="#feedback"]')
        end
      end
    end
  end
end
