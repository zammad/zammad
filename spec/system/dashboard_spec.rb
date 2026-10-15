# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Dashboard', type: :system do

  it 'shows default widgets' do
    visit 'dashboard'

    expect(page).to have_css('.stat-widgets')
    expect(page).to have_css('.ticket_waiting_time > div > div.stat-title', text: %r{∅ Waiting time today}i)
    expect(page).to have_css('.ticket_escalation > div > div.stat-title', text: %r{Mood}i)
    expect(page).to have_css('.ticket_channel_distribution > div > div.stat-title', text: %r{Channel Distribution}i)
    expect(page).to have_css('.ticket_load_measure > div > div.stat-title', text: %r{Assigned}i)
    expect(page).to have_css('.ticket_in_process > div > div.stat-title', text: %r{My tickets in process}i)
    expect(page).to have_css('.ticket_reopen > div > div.stat-title', text: %r{Reopening rate}i)
  end

  context 'when customer role is named different', authenticated_as: :authenticate do
    def authenticate
      Role.find_by(name: 'Customer').update(name: 'Public')
      true
    end

    it 'invites a customer user' do
      visit 'dashboard'
      find('div.tab[data-area=first-steps-widgets]').click
      find('.js-inviteCustomer').click
      fill_in 'firstname', with: 'Nick'
      fill_in 'lastname', with: 'Braun'
      fill_in 'Email', with: 'nick.braun@zammad.org'
      click_on 'Invite'
      await_empty_ajax_queue
      expect(User.find_by(firstname: 'Nick').roles).to eq([Role.find_by(name: 'Public')])
    end
  end

  context 'when the dashboard is turned off', authenticated_as: :authenticate do
    def authenticate
      Setting.set('dashboard', false)
      true
    end

    it 'redirects to the overviews' do
      visit 'dashboard'

      expect_current_route 'ticket/view'
    end

    it 'hides the navigation entry' do
      visit 'ticket/view'

      expect(page).to have_css('#navigation [href="#ticket/view"]')
      expect(page).to have_no_css('#navigation [href="#dashboard"]')
    end

    it 'hides the shortcut from the list of shortcuts' do
      visit 'keyboard_shortcuts'

      in_modal do
        expect(page).to have_text('Overviews')
        expect(page).to have_no_text('Dashboard')
      end
    end

    it 'ignores the shortcut' do
      ticket = create(:ticket, group: Group.find_by(name: 'Users'))
      visit "ticket/zoom/#{ticket.id}"

      send_keys(['h'])

      expect_current_route "ticket/zoom/#{ticket.id}"
    end

    it 'ignores the shortcut of the desktop app' do
      ticket = create(:ticket, group: Group.find_by(name: 'Users'))
      visit "ticket/zoom/#{ticket.id}"

      # The desktop app sends its global shortcuts as this event.
      page.execute_script("App.Event.trigger('global-shortcut', 'dashboard')")

      expect_current_route "ticket/zoom/#{ticket.id}"
    end
  end

  context 'when the dashboard gets turned off while it is open' do
    before do
      visit 'dashboard'
      wait_for_authenticated_session
    end

    it 'hides the navigation entry and shows the overviews' do
      expect(page).to have_css('#navigation [href="#dashboard"]')

      Setting.set('dashboard', false)

      expect(page).to have_no_css('#navigation [href="#dashboard"]')
      expect_current_route 'ticket/view'
    end
  end

  context 'when the dashboard gets turned off while another page is open' do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    before do
      visit "ticket/zoom/#{ticket.id}"
      wait_for_authenticated_session
    end

    it 'hides the navigation entry and stays on the page' do
      expect(page).to have_css('#navigation [href="#dashboard"]')

      Setting.set('dashboard', false)

      expect(page).to have_no_css('#navigation [href="#dashboard"]')
      expect_current_route "ticket/zoom/#{ticket.id}"
    end
  end

  context 'when the dashboard gets turned on', authenticated_as: :authenticate do
    def authenticate
      Setting.set('dashboard', false)
      true
    end

    before do
      visit 'ticket/view'
      wait_for_authenticated_session
    end

    it 'shows the navigation entry and the dashboard' do
      expect(page).to have_no_css('#navigation [href="#dashboard"]')

      Setting.set('dashboard', true)
      click '#navigation [href="#dashboard"]'

      within :active_content do
        expect(page).to have_text('My Stats')
      end
    end
  end

  context 'when first steps are turned off', authenticated_as: :authenticate do
    def authenticate
      Setting.set('dashboard_first_steps', false)
      true
    end

    it 'hides the first steps tab' do
      visit 'dashboard'

      within :active_content do
        expect(page).to have_text('My Stats')
        expect(page).to have_no_css('div.tab[data-area=first-steps-widgets]')
      end
    end
  end

  context 'when a stats widget is turned off', authenticated_as: :authenticate do
    def authenticate
      Setting.set('dashboard_stats_ticket_escalation', false)
      true
    end

    it 'hides the widget' do
      visit 'dashboard'

      expect(page).to have_css('.ticket_waiting_time')
      expect(page).to have_no_css('.ticket_escalation')
    end
  end

  context 'when a stats widget gets turned off while the dashboard is open' do
    before do
      visit 'dashboard'
      wait_for_authenticated_session
    end

    it 'hides the widget' do
      expect(page).to have_css('.ticket_escalation')

      Setting.set('dashboard_stats_ticket_escalation', false)

      expect(page).to have_no_css('.ticket_escalation')
    end
  end

  context 'when all stats widgets are turned off', authenticated_as: :authenticate do
    def authenticate
      %w[
        dashboard_stats_ticket_waiting_time dashboard_stats_ticket_escalation dashboard_stats_ticket_channel_distribution
        dashboard_stats_ticket_load_measure dashboard_stats_ticket_in_process dashboard_stats_ticket_reopen
      ].each { |name| Setting.set(name, false) }
      true
    end

    it 'hides the stats tab and shows the first steps' do
      visit 'dashboard'

      within :active_content do
        expect(page).to have_css('div.tab.active[data-area=first-steps-widgets]')
        expect(page).to have_css('.tab-content.first-steps-widgets:not(.hidden)')
        expect(page).to have_no_text('My Stats')
      end
    end

    context 'with an addon widget the agent may not see' do
      def authenticate
        super
        create(:agent)
      end

      it 'still hides the stats tab and shows the first steps' do
        visit 'dashboard'
        expect(page).to have_css('div.tab.active[data-area=first-steps-widgets]')

        page.execute_script(<<~JS)
          App.Config.set('addon_widget', { prio: 700, permission: 'admin', className: 'addon_widget', title: 'Addon widget' }, 'Stats')
          App.Event.trigger('ui:rerender')
        JS

        within :active_content do
          expect(page).to have_css('div.tab.active[data-area=first-steps-widgets]')
          expect(page).to have_no_text('My Stats')
        end
      end
    end

    context 'when first steps are turned off too' do
      def authenticate
        Setting.set('dashboard_first_steps', false)
        super
      end

      it 'shows a hint instead of the tabs' do
        visit 'dashboard'

        within :active_content do
          expect(page).to have_css('.dashboard-empty-state', text: 'Oops, seems like all the dashboard widgets have been turned off for you. Please contact your administrator.')
          expect(page).to have_css('.dashboard-empty-state img')
          expect(page).to have_no_css('.dashboard .tabs', visible: :all)
        end
      end
    end
  end

  context 'Session Timeout' do
    let(:admin)    { create(:admin) }
    let(:agent)    { create(:agent) }
    let(:customer) { create(:customer) }

    def frontend_session_timeout
      page.evaluate_script('App.Plugin.instance().backend.session_timeout.getTimeout()')
    end

    before do
      visit '/'
      ensure_websocket(check_if_pinged: false)
      wait_for_authenticated_session # fast relog causes race conditions in websocket server
    end

    context 'Logout by frontend plugin - Default', authenticated_as: :authenticate do
      def authenticate
        Setting.set('session_timeout', { default: '1' })
        admin
      end

      it 'does logout user' do
        expect(page).to have_text('Due to inactivity, you will be automatically logged out within the next 30 seconds.')
        expect(page).to have_text('Due to inactivity, you have been automatically logged out.')
      end
    end

    context 'Logout by frontend plugin - Setting change', authenticated_as: :admin do
      it 'does logout user' do
        expect(page).to have_no_text('Due to inactivity, you have been automatically logged out.')
        Setting.set('session_timeout', { default: '1' })
        expect(page).to have_text('Due to inactivity, you have been automatically logged out.')
      end
    end

    context 'Logout by frontend plugin - Admin', authenticated_as: :authenticate do
      def authenticate
        Setting.set('session_timeout', { admin: '1', default: '1000' })
        admin
      end

      it 'does logout user' do
        expect(page).to have_text('Due to inactivity, you have been automatically logged out.')
      end
    end

    context 'Logout by frontend plugin - Agent', authenticated_as: :authenticate do
      def authenticate
        Setting.set('session_timeout', { 'ticket.agent': '1', default: '1000' })
        agent
      end

      it 'does logout user' do
        expect(page).to have_text('Due to inactivity, you have been automatically logged out.')
      end
    end

    context 'Logout by frontend plugin - Customer', authenticated_as: :authenticate do
      def authenticate
        Setting.set('session_timeout', { 'ticket.customer': '1', default: '1000' })
        customer
      end

      it 'does logout user' do
        expect(page).to have_text('Due to inactivity, you have been automatically logged out.')
      end
    end

    context 'Logout by SessionTimeoutJob - frontend_timeout' do
      it 'does logout user', authenticated_as: :admin do

        # because of the websocket server running in the same
        # process and the checks in the frontend it is really
        # hard test the SessionTimeoutJob.perform_now here
        # so we only check the session killing code and use
        # backend tests for the reset
        session = ActiveRecord::SessionStore::Session.all.detect { |s| s.data['user_id'] == admin.id }
        SessionTimeoutJob::Session.new(session).frontend_timeout
        expect(page).to have_text('Due to inactivity, you have been automatically logged out.')
      end
    end

    context 'Logout by frontend plugin - Fallback from admin to default', authenticated_as: :authenticate do
      def authenticate
        Setting.set('session_timeout', { admin: '0', default: '1000' })
        admin
      end

      it 'uses the default timeout' do
        expect(frontend_session_timeout).to eq(1000 * 1000)
      end
    end

    context 'Logout by frontend plugin - No logout because timeouts are disabled', authenticated_as: :authenticate do
      def authenticate
        Setting.set('session_timeout', { admin: '0', default: '0' })
        admin
      end

      it 'disables the logout timer' do
        expect(frontend_session_timeout).to eq(0)
      end
    end
  end
end
