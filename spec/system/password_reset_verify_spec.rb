# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Password Reset verify', authenticated_as: false, type: :system do
  context 'with a valid token' do
    let(:user)  { create(:agent) }
    let(:token) { User.password_reset_new_token(user.email)[:token] }

    before do
      visit "password_reset_verify/#{token.token}"
    end

    it 'resetting password with non matching passwords fail' do
      fill_in 'password', with: 'some'
      fill_in 'password_confirm', with: 'some2'

      click '.js-passwordForm .js-submit'

      expect(page).to have_text 'passwords do not match'
    end

    it 'resetting password with weak password fail' do
      fill_in 'password', with: 'some'
      fill_in 'password_confirm', with: 'some'

      click '.js-passwordForm .js-submit'

      expect(page).to have_text 'Invalid password'
    end

    it 'successfully resets password and logs in' do
      new_password = generate(:password_valid)

      fill_in 'password', with: new_password
      fill_in 'password_confirm', with: new_password

      click '.js-passwordForm .js-submit'

      expect(page).to have_text('Your password has been changed')
        .and have_css(".user-menu .user a[title=#{user.login}")
    end

    context 'with a mandatory 2FA setup' do
      let(:user) { create(:agent).tap { |user| user.roles << role } }
      let(:role) { create(:role, :agent, name: '2FA') }

      before do
        Setting.set('two_factor_authentication_enforce_role_ids', [role.id])
        Setting.set('two_factor_authentication_method_authenticator_app', true)
        Setting.set('two_factor_authentication_recovery_codes', true)
      end

      it 'does not error out on recovery codes dialog (#5646)' do
        new_password = generate(:password_valid)

        fill_in 'password', with: new_password
        fill_in 'password_confirm', with: new_password

        click '.js-passwordForm .js-submit'

        in_modal do
          click '.js-configuration-method'
          click '.qr-code-canvas'

          secret = find('.secret').text
          security_code = ROTP::TOTP.new(secret).now

          fill_in 'Security Code', with: security_code

          click_on 'Set Up'
          click_on "OK, I've saved my recovery codes"
        end

        expect(page).to have_no_css('.modal')
        expect(user.reload.two_factor_configured?).to be(true)
      end
    end
  end

  context 'without a valid token' do
    it 'error shown if opened with a not existing token' do
      visit 'password_reset_verify/not_existing_token'

      expect(page).to have_text 'Token is invalid'
    end
  end
end
