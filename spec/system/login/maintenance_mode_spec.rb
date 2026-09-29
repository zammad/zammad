# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Login Maintenance Mode', authenticated_as: false, type: :system do
  def try_login(username, password)
    within('#login') do
      fill_in 'username', with: username
      fill_in 'password', with: password

      click_on 'Sign in'
    end
  end

  context 'with maintenance_mode' do
    context 'with active maintenance_mode' do
      before { Setting.set 'maintenance_mode', true }

      it 'shows maintenance mode' do
        open_login_page

        expect(page).to have_css('.js-maintenanceMode')

        try_login('agent1@example.com', 'test')

        expect(page).to have_css('#login .alert')

        refresh

        try_login('nicole.braun@zammad.org', 'test')

        expect(page).to have_css('#login .alert')

        refresh

        try_login('admin@example.com', 'test')

        expect(find('.user-menu .user a')[:title]).to eq('admin@example.com')
      end

      it 'login should work again after deactivation of maintenance mode' do
        open_login_page

        expect(page).to have_css('.js-maintenanceMode')

        try_login('agent1@example.com', 'test')

        expect(page).to have_css('#login .alert')

        Setting.set 'maintenance_mode', false

        wait_for_setting('maintenance_mode', false)

        refresh

        expect(page).to have_no_css('.js-maintenanceMode')

        try_login('agent1@example.com', 'test')

        expect(find('.user-menu .user a')[:title]).to eq('agent1@example.com')
      end
    end

    context 'without maintenance_mode' do
      before { Setting.set 'maintenance_mode', false }

      it 'does not show message' do
        open_login_page

        expect(page).to have_no_css('.js-maintenanceMode')
      end

      it 'shows message on the go' do
        open_login_page

        Setting.set 'maintenance_mode', true

        await_empty_ajax_queue

        expect(page).to have_css('.js-maintenanceMode', wait: 30)
      end
    end
  end

  context 'with import_mode' do
    context 'with active import_mode' do
      before { Setting.set 'import_mode', true }

      it 'shows maintenance mode and lets only administrators in' do
        open_login_page

        expect(page).to have_css('.js-maintenanceMode')

        try_login('agent1@example.com', 'test')

        expect(page).to have_css('#login .alert')

        refresh

        try_login('admin@example.com', 'test')

        expect(find('.user-menu .user a')[:title]).to eq('admin@example.com')
      end

      it 'hides message on the go' do
        open_login_page

        expect(page).to have_css('.js-maintenanceMode')

        Setting.set 'import_mode', false

        await_empty_ajax_queue

        expect(page).to have_no_css('.js-maintenanceMode', wait: 30)
      end
    end

    context 'without import_mode' do
      before { Setting.set 'import_mode', false }

      it 'shows message on the go' do
        open_login_page

        Setting.set 'import_mode', true

        await_empty_ajax_queue

        expect(page).to have_css('.js-maintenanceMode', wait: 30)
      end
    end

    context 'with an open session' do
      before { Setting.set 'import_mode', false }

      def wait_for_client_config(name, value)
        wait.until { page.evaluate_script("App.Config.get('#{name}')") == value }
      end

      context 'with an agent', authenticated_as: :agent do
        let(:agent) { create(:agent) }

        it 'logs the agent out when import mode turns on' do
          visit '/'
          wait_for_authenticated_session(user: agent)

          Setting.set 'import_mode', true

          expect(page).to have_css('#login', wait: 30)
        end
      end

      context 'with an administrator', authenticated_as: true do
        it 'keeps the administrator logged in when import mode turns on' do
          visit '/'
          wait_for_authenticated_session

          Setting.set 'import_mode', true

          wait_for_client_config('import_mode', true)

          expect(page).to have_no_css('#login')
          expect(page).to have_css('.user-menu .user')
        end
      end

      context 'with a session switched into an agent by a maintenance administrator', authenticated_as: true do
        let(:agent) { create(:agent) }

        it 'keeps the switched session when import mode turns on' do
          visit "/api/v1/sessions/switch/#{agent.id}"
          visit '/'
          wait_for_authenticated_session(user: agent)

          expect(page).to have_css('.switchBackToUser')

          Setting.set 'import_mode', true

          wait_for_client_config('import_mode', true)

          expect(page).to have_no_css('#login')
          expect(page).to have_css('.switchBackToUser')
        end
      end
    end
  end

  def open_login_page
    visit '/'

    ensure_websocket
    ensure_websocket_push_delivery
  end
end
