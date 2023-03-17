# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Login Maintenance Mode', authenticated_as: false, type: :system do
  context 'with maintenance_mode' do
    def try_login(username, password)
      within('#login') do
        fill_in 'username', with: username
        fill_in 'password', with: password

        click_button
      end
    end

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

        expect(page).to have_no_css('.js-maintenanceMode', wait: 30)

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

  def open_login_page
    visit '/'

    ensure_websocket
  end
end
