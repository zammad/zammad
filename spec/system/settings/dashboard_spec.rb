# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Settings > Dashboard', type: :system do
  context 'with admin.dashboard permission', authenticated_as: :authenticate do
    let(:role) { create(:role, permission_names: %w[admin.dashboard]) }
    let(:user) { create(:user, roles: [role]) }

    def authenticate
      user
    end

    before { visit '/#settings/dashboard' }

    it 'shows the dashboard menu item' do
      within '.sidebar' do
        expect(page).to have_link('Dashboard', href: '#settings/dashboard')
      end
    end

    it 'turns the dashboard off and disables its elements, keeping their values' do
      within :active_content do
        click '.js-header-switch'
      end

      await_empty_ajax_queue

      expect(Setting.get('dashboard')).to be(false)

      within :active_content do
        expect(page).to have_select('dashboard_activity_stream', selected: 'All activities', disabled: true)
        expect(page).to have_checked_field('dashboard_first_steps', disabled: true, visible: :all)
        expect(page).to have_checked_field('dashboard_stats_ticket_escalation', disabled: true, visible: :all)
      end
    end

    context 'with the dashboard turned off' do
      def authenticate
        Setting.set('dashboard', false)

        user
      end

      it 'turns the dashboard on and enables its elements' do
        within :active_content do
          click '.js-header-switch'
        end

        await_empty_ajax_queue

        expect(Setting.get('dashboard')).to be(true)

        within :active_content do
          expect(page).to have_select('dashboard_activity_stream', selected: 'All activities', disabled: false)
          expect(page).to have_checked_field('dashboard_first_steps', disabled: false, visible: :all)
        end
      end
    end

    it 'turns the activity stream off' do
      within :active_content do
        select 'Do not show activities', from: 'dashboard_activity_stream'
      end

      await_empty_ajax_queue

      expect(Setting.get('dashboard_activity_stream')).to be(false)
    end

    it 'limits the activity stream to own activities', :aggregate_failures do
      within :active_content do
        select 'Own activities only', from: 'dashboard_activity_stream'
      end

      await_empty_ajax_queue

      expect(Setting.get('dashboard_activity_stream')).to be(true)
      expect(Setting.get('dashboard_activity_stream_own')).to be(true)
    end

    it 'keeps the activity stream off when turned off while the limit is still saving', :aggregate_failures do
      within :active_content do
        expect(page).to have_select('dashboard_activity_stream', selected: 'All activities')
      end

      # Both choices are made in one go, so the second one comes before the limit is saved.
      page.execute_script(<<~JS)
        $('#dashboard_activity_stream').val('own').trigger('change')
        $('#dashboard_activity_stream').val('off').trigger('change')
      JS

      await_empty_ajax_queue

      expect(Setting.get('dashboard_activity_stream')).to be(false)
      expect(Setting.get('dashboard_activity_stream_own')).to be(true)
    end

    context 'with the activity stream turned off' do
      def authenticate
        Setting.set('dashboard_activity_stream', false)

        user
      end

      it 'turns the activity stream on once limited to own activities', :aggregate_failures do
        within :active_content do
          select 'Own activities only', from: 'dashboard_activity_stream'

          expect(page).to have_select('dashboard_activity_stream', selected: 'Own activities only')
        end

        await_empty_ajax_queue

        expect(Setting.get('dashboard_activity_stream_own')).to be(true)
        expect(Setting.get('dashboard_activity_stream')).to be(true)
      end

      it 'turns the activity stream on with all activities', :aggregate_failures do
        within :active_content do
          select 'All activities', from: 'dashboard_activity_stream'
        end

        await_empty_ajax_queue

        expect(Setting.get('dashboard_activity_stream')).to be(true)
        expect(Setting.get('dashboard_activity_stream_own')).to be(false)
      end
    end

    context 'with the activity stream limited to own activities' do
      def authenticate
        Setting.set('dashboard_activity_stream_own', true)

        user
      end

      it 'shows the saved value and shows all activities again', :aggregate_failures do
        within :active_content do
          expect(page).to have_select('dashboard_activity_stream', selected: 'Own activities only')

          select 'All activities', from: 'dashboard_activity_stream'
        end

        await_empty_ajax_queue

        expect(Setting.get('dashboard_activity_stream')).to be(true)
        expect(Setting.get('dashboard_activity_stream_own')).to be(false)
      end
    end

    context 'with the first steps turned off' do
      def authenticate
        Setting.set('dashboard_first_steps', false)

        user
      end

      it 'shows the saved values and turns the first steps on' do
        within :active_content do
          expect(page).to have_select('dashboard_activity_stream', selected: 'All activities')
          expect(page).to have_unchecked_field('dashboard_first_steps', visible: :all)

          within('.js-dashboardElement', text: 'First Steps') { find('label').click }
        end

        await_empty_ajax_queue

        expect(Setting.get('dashboard_first_steps')).to be(true)
      end
    end

    it 'turns a stats widget off' do
      within :active_content do
        click_on 'Dashboard widgets'
        within('.js-dashboardElement', text: 'Mood') { find('label').click }
      end

      await_empty_ajax_queue

      expect(Setting.get('dashboard_stats_ticket_escalation')).to be(false)
    end

    context 'with stats widgets from an addon' do
      def authenticate
        create(:setting, name: 'dashboard_stats_addon_widget', area: 'Dashboard::Base', state: true, frontend: true, preferences: { permission: ['admin.dashboard'] })

        user
      end

      it 'shows a toggle only for the widget with its own setting', :aggregate_failures do
        page.execute_script(<<~JS)
          App.Config.set('addon_widget', { prio: 700, className: 'addon_widget', title: 'Addon widget', description: 'Shows addon stats.' }, 'Stats')
          App.Config.set('other_addon_widget', { prio: 800, className: 'other_addon_widget', title: 'Other addon widget', description: 'Shows other addon stats.' }, 'Stats')
          App.Event.trigger('ui:rerender')
        JS

        within :active_content do
          click_on 'Dashboard widgets'

          expect(page).to have_css('.js-dashboardElement', text: 'Addon widget')
          expect(page).to have_checked_field('dashboard_stats_addon_widget', visible: :all)
          expect(page).to have_no_css('.js-dashboardElement', text: 'Other addon widget')
        end
      end
    end

    context 'with all stats widgets turned off' do
      def authenticate
        %w[
          dashboard_stats_ticket_waiting_time dashboard_stats_ticket_escalation dashboard_stats_ticket_channel_distribution
          dashboard_stats_ticket_load_measure dashboard_stats_ticket_in_process dashboard_stats_ticket_reopen
        ].each { |name| Setting.set(name, false) }

        user
      end

      it 'shows a hint once the views are turned off too, until the dashboard is turned off' do
        within :active_content do
          within('.js-dashboardElement', text: 'First Steps') { find('label').click }

          expect(page).to have_unchecked_field('dashboard_first_steps', visible: :all)
          expect(page).to have_no_css('.alert--warning')

          select 'Do not show activities', from: 'dashboard_activity_stream'

          expect(page).to have_css('.alert--warning', text: 'All views and widgets are turned off, so agents see an empty dashboard. If you do not need the dashboard at all, you can turn it off.')

          within('.js-dashboardElement', text: 'First Steps') { find('label').click }

          expect(page).to have_no_css('.alert--warning')

          within('.js-dashboardElement', text: 'First Steps') { find('label').click }

          expect(page).to have_css('.alert--warning')

          click '.js-header-switch'

          expect(page).to have_no_css('.alert--warning')
        end
      end
    end
  end

  context 'without admin.dashboard permission', authenticated_as: :user do
    let(:role) { create(:role, permission_names: %w[admin.group]) }
    let(:user) { create(:user, roles: [role]) }

    before { visit '/#manage' }

    it 'does not show the dashboard menu item' do
      within '.sidebar' do
        expect(page).to have_no_link('Dashboard', href: '#settings/dashboard')
      end
    end
  end
end
