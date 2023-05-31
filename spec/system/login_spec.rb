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
    let(:user)               { User.find_by(login: 'admin@example.com') }
    let!(:authenticator_2fa) { create(:user_two_factor_preference, :authenticator_app, user:) }

    before do
      authenticator_2fa
      stub_const('Auth::BRUTE_FORCE_SLEEP', 0)
    end

    context 'with authenticator app' do
      let(:token) { authenticator_2fa.configuration[:code] }

      before do
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
      let(:token)        { 'token' }
      let(:recovery_2fa) { create(:user_two_factor_preference, :recovery_codes, token:, user:) }

      before do
        recovery_2fa
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
