# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Login', authenticated_as: false, type: :system do
  context 'with standard authentication' do
    before do
      visit '/'
    end

    it 'fqdn is visible on login page' do
      expect(page).to have_css('.login p', text: Setting.get('fqdn'))
    end

    it 'Login with wrong credentials' do
      within('#login') do
        fill_in 'username', with: 'admin@example.com'
        fill_in 'password', with: 'wrong'

        click_button
      end

      expect(page).to have_css('#login .alert')
    end
  end

  context 'with enabled two factor authentication' do
    let(:token)            { two_factor_pref.configuration[:code] }
    let!(:two_factor_pref) { create(:'user/two_factor_preference', user: User.find_by(login: 'admin@example.com')) }

    before do
      stub_const('Auth::BRUTE_FORCE_SLEEP', 0)
      visit '/'

      within('#login') do
        fill_in 'username', with: 'admin@example.com'
        fill_in 'password', with: 'test'

        click_button
      end
    end

    it 'login with correct payload' do
      within('#login') do
        fill_in 'security_code', with: token

        click_button
      end

      expect(page).to have_no_selector('#login')
    end

    it 'login with wrong payload' do
      within('#login') do
        fill_in 'security_code', with: 'asd'

        click_button
      end

      expect(page).to have_css('#login .alert')
    end
  end
end
