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
    let(:user) { User.find_by(login: 'admin@example.com') }

    context 'with security keys method' do
      before do
        skip('Mocking of Web Authentication API is currently supported only in Chrome.') if Capybara.current_driver != :zammad_chrome

        stub_const('Auth::BRUTE_FORCE_SLEEP', 0)
        visit '/'

        # TODO: Remove once our CI runs only in secure context.
        is_secure_context = page.execute_script('return window.isSecureContext;')
        skip('Test currently unsupported in insecure contexts.') if !is_secure_context

        # We can only mock the security key within the loaded app.
        two_factor_pref

        refresh

        within('#login') do
          fill_in 'username', with: 'admin@example.com'
          fill_in 'password', with: 'test'

          click_button
        end
      end

      context 'with the configured security key present' do
        let(:two_factor_pref) { create(:user_two_factor_preference, :mocked_security_keys, user: user, page: page) }

        it 'signs in with the correct security key present' do
          expect(page).to have_no_selector('#login')
        end
      end

      context 'with the incorrect security key present' do
        let(:two_factor_pref) { create(:user_two_factor_preference, :mocked_security_keys, user: user, page: page, wrong_key: true) }

        it 'shows error and retry button' do
          expect(page).to have_css('#login .alert')
          expect(page).to have_css('.js-retry')
        end
      end
    end

    context 'with authenticator app method' do
      let(:token)            { two_factor_pref.configuration[:code] }
      let!(:two_factor_pref) { create(:user_two_factor_preference, :authenticator_app, user: user) }

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

    context 'with recovery code' do
      let(:token)           { 'token' }
      let(:two_factor_pref) { create(:user_two_factor_preference, :authenticator_app, user: user) }
      let(:recovery_2fa)    { create(:user_two_factor_preference, :recovery_codes, recovery_code: token, user: user) }

      before do
        two_factor_pref && recovery_2fa
        Setting.set('two_factor_authentication_recovery_codes', recovery_codes_enabled)

        visit '/'

        within('#login') do
          fill_in 'username', with: 'admin@example.com'
          fill_in 'password', with: 'test'

          click_button
        end
      end

      context 'when recovery code is enabled' do
        let(:recovery_codes_enabled) { true }

        before do
          click_on 'Try another method'
          click_on 'recovery codes'
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
            fill_in 'security_code', with: 'wrong token'
            click_button
          end

          expect(page).to have_css('#login .alert')
        end
      end

      context 'when recovery code is disabled' do
        let(:recovery_codes_enabled) { false }

        it 'recovery code link is hidden' do
          expect(page).to have_no_text 'Try another method'
        end
      end
    end
  end
end
