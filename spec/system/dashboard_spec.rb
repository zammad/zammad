# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Dashboard', type: :system, authenticated_as: true do

  it 'shows default widgets' do
    visit 'dashboard'

    expect(page).to have_css('.stat-widgets')
    expect(page).to have_css('.ticket_waiting_time > div > div.stat-title', text: %r{∅ Waiting time today}i)
    expect(page).to have_css('.ticket_escalation > div > div.stat-title', text: %r{Mood}i)
    expect(page).to have_css('.ticket_channel_distribution > div > div.stat-title', text: %r{Channel Distribution}i)
    expect(page).to have_css('.ticket_load_measure > div > div.stat-title', text: %r{Assigned}i)
    expect(page).to have_css('.ticket_in_process > div > div.stat-title', text: %r{Your tickets in process}i)
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
      fill_in 'Firstname', with: 'Nick'
      fill_in 'Lastname', with: 'Braun'
      fill_in 'Email', with: 'nick.braun@zammad.org'
      click_on 'Invite'
      await_empty_ajax_queue
      expect(User.find_by(firstname: 'Nick').roles).to eq([Role.find_by(name: 'Public')])
    end
  end

  context 'Session Timeout' do
    let(:admin) { create(:admin) }
    let(:agent) { create(:agent) }
    let(:customer) { create(:customer) }

    before do
      ensure_websocket(check_if_pinged: false)
    end

    context 'Logout by frontend plugin - Default', authenticated_as: :authenticate do
      def authenticate
        Setting.set('session_timeout', { default: '1' })
        admin
      end

      it 'does logout user' do
        expect(page).to have_text('Due to inactivity are automatically logged out within the next 30 seconds.', wait: 20)
        expect(page).to have_text('Due to inactivity you are automatically logged out.', wait: 20)
      end

      it 'does not logout user', authenticated_as: :admin do
        sleep 1.5
        expect(page).to have_no_text('Due to inactivity you are automatically logged out.', wait: 0)
      end
    end

    context 'Logout by frontend plugin - Setting change', authenticated_as: :admin do
      it 'does logout user' do
        expect(page).to have_no_text('Due to inactivity you are automatically logged out.')
        Setting.set('session_timeout', { default: '1' })
        expect(page).to have_text('Due to inactivity you are automatically logged out.', wait: 20)
      end
    end

    context 'Logout by frontend plugin - Admin', authenticated_as: :authenticate do
      def authenticate
        Setting.set('session_timeout', { admin: '1', default: '1000' })
        admin
      end

      it 'does logout user' do
        expect(page).to have_text('Due to inactivity you are automatically logged out.', wait: 20)
      end
    end

    context 'Logout by frontend plugin - Agent', authenticated_as: :authenticate do
      def authenticate
        Setting.set('session_timeout', { 'ticket.agent': '1', default: '1000' })
        agent
      end

      it 'does logout user' do
        expect(page).to have_text('Due to inactivity you are automatically logged out.', wait: 20)
      end
    end

    context 'Logout by frontend plugin - Customer', authenticated_as: :authenticate do
      def authenticate
        Setting.set('session_timeout', { 'ticket.customer': '1', default: '1000' })
        customer
      end

      it 'does logout user' do
        expect(page).to have_text('Due to inactivity you are automatically logged out.', wait: 20)
      end
    end

    context 'Logout by SessionTimeoutJob - destroy_session' do
      it 'does logout user', authenticated_as: :admin do

        # because of the websocket server running in the same
        # process and the checks in the frontend it is really
        # hard test the SessionTimeoutJob.perform_now here
        # so we only check the session killing code and use
        # backend tests for the rest
        session = ActiveRecord::SessionStore::Session.all.detect { |s| s.data['user_id'] == admin.id }
        SessionTimeoutJob.destroy_session(admin, session)
        expect(page).to have_text('Due to inactivity you are automatically logged out.', wait: 20)
      end
    end

    context 'Logout by frontend plugin - Fallback from admin to default', authenticated_as: :authenticate do
      def authenticate
        Setting.set('session_timeout', { admin: '0', default: '1000' })
        admin
      end

      it 'does not logout user', authenticated_as: :admin do
        sleep 1.5
        expect(page).to have_no_text('Due to inactivity you are automatically logged out.', wait: 0)
      end
    end

    context 'Logout by frontend plugin - No logout because timeouts are disabled', authenticated_as: :authenticate do
      def authenticate
        Setting.set('session_timeout', { admin: '0', default: '0' })
        admin
      end

      it 'does not logout user', authenticated_as: :admin do
        sleep 1.5
        expect(page).to have_no_text('Due to inactivity you are automatically logged out.', wait: 0)
      end
    end
  end
end
