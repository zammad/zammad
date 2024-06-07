# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Personal Setting > Security', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:agent) { create(:agent) }

  def go_to_personal_setting
    visit '/'
    find("[aria-label=\"Avatar (#{agent.fullname})\"]").click
    click_on 'Profile settings'
  end

  describe 'password change' do
    let(:agent) { create(:agent, password: 'test') }

    it 'user can change password' do
      go_to_personal_setting
      click_on 'Password'

      fill_in 'Current password', with: 'test'
      fill_in 'New password', with: 'testTEST1234'
      fill_in 'Confirm new password', with: 'testTEST1234'

      click_on 'Change Password'

      expect(page).to have_text('Password changed successfully')
    end
  end

  describe 'two-factor authentication handling' do
    let(:agent) { create(:agent, password: 'test') }

    context 'with security keys method' do
      before do
        skip('Mocking of Web Authentication API is currently supported only in Chrome.') if Capybara.current_driver != :zammad_chrome
        Setting.set('two_factor_authentication_method_security_keys', true)
        Setting.set('two_factor_authentication_recovery_codes', false)
        Setting.set('two_factor_authentication_enforce_role_ids', [])
      end

      it 'can set up and use the method' do
        go_to_personal_setting
        click_on 'Two-factor Authentication'

        click_on 'Set up security keys'

        fill_in 'Current password', with: 'test'
        click_on 'Next'

        click_on 'Set Up'

        fill_in 'Name for this security key', with: Faker::Lorem.unique.word

        # Mock a U2F key via the Selenium virtual authenticator feature (supported only by Chrome ATM).
        #   A virtual authenticator instance will be set up for the remainder of the browser session.
        #   We will reuse it later during the login phase.
        options = Selenium::WebDriver::VirtualAuthenticatorOptions.new(protocol: :u2f, transport: :usb, resident_key: false,
                                                                       user_consenting: true, user_verification: true,
                                                                       user_verified: true)
        page.driver.browser.add_virtual_authenticator(options)

        click_on 'Next'

        expect(page).to have_text('Two-factor authentication method was set up successfully.')

        # Logout
        find("[aria-label=\"Avatar (#{agent.fullname})\"]").click
        click_on 'Sign out'

        # Login
        fill_in 'Username / Email', with: agent.login
        fill_in 'Password', with: 'test'
        click_on 'Sign in'

        # Mocked key via the virtual authenticator will be accessed again right about here.

        expect(page).to have_current_route('/')
      end
    end

    context 'with authenticator app method' do
      before do
        Setting.set('two_factor_authentication_method_authenticator_app', true)
        Setting.set('two_factor_authentication_recovery_codes', false)
      end

      describe 'when using optional setup in personal settings' do
        before do
          Setting.set('two_factor_authentication_enforce_role_ids', [])
        end

        it 'can set up and use the method' do
          go_to_personal_setting
          click_on 'Two-factor Authentication'

          click_on 'Set up authenticator app'

          fill_in 'Current password', with: 'test'
          click_on 'Next'

          find('canvas').click
          secret = find('#qr-code-secret-overlay > span').text
          fill_in('securityCode', with: ROTP::TOTP.new(secret).now)
          click_on 'Set Up'
          expect(page).to have_text('Two-factor method has been configured successfully.')

          # Logout
          find("[aria-label=\"Avatar (#{agent.fullname})\"]").click
          click_on 'Sign out'

          # Workaround for a non-reusable OTP inside the 30s window.
          #   Set the last OTP timestamp in the 2FA configuration to a time window in the past.
          two_factor_pref = agent.two_factor_preferences.last
          two_factor_pref.configuration[:last_otp_at] = 30.seconds.ago.to_i
          two_factor_pref.save!

          # Login
          fill_in 'Username / Email', with: agent.login
          fill_in 'Password', with: 'test'
          click_on 'Sign in'

          # 2FA Code
          fill_in('Security Code', with: ROTP::TOTP.new(secret).now)
          click_on('Sign in')
          expect(page).to have_current_route('/')
        end
      end

      describe 'when using mandatory setup after authentication' do
        before do
          Setting.set('two_factor_authentication_enforce_role_ids', [Role.lookup(name: 'Agent').id])
        end

        it 'can set up and use the method' do
          visit '/'

          expect(page).to have_text('Set Up Two-factor Authentication')
          expect(page).to have_text('You must protect your account with two-factor authentication.')
          expect(page).to have_text('Choose your preferred two-factor authentication method to set it up.')

          click_on 'Authenticator App'

          find('canvas').click
          secret = find('#qr-code-secret-overlay > span').text
          fill_in('securityCode', with: ROTP::TOTP.new(secret).now)
          click_on 'Set Up'
          expect(page).to have_text('Two-factor method has been configured successfully.')

          # Logout
          find("[aria-label=\"Avatar (#{agent.fullname})\"]").click
          click_on 'Sign out'

          # Workaround for a non-reusable OTP inside the 30s window.
          #   Set the last OTP timestamp in the 2FA configuration to a time window in the past.
          two_factor_pref = agent.two_factor_preferences.last
          two_factor_pref.configuration[:last_otp_at] = 30.seconds.ago.to_i
          two_factor_pref.save!

          # Login
          fill_in 'Username / Email', with: agent.login
          fill_in 'Password', with: 'test'
          click_on 'Sign in'

          # 2FA Code
          fill_in('Security Code', with: ROTP::TOTP.new(secret).now)
          click_on('Sign in')
          expect(page).to have_current_route('/')
        end
      end
    end

    context 'with recovery codes enabled' do
      before do
        Setting.set('two_factor_authentication_method_authenticator_app', true)
        Setting.set('two_factor_authentication_recovery_codes', true)
        Setting.set('two_factor_authentication_enforce_role_ids', [])
      end

      it 'can use a pre-generated code to login' do
        go_to_personal_setting
        click_on 'Two-factor Authentication'

        click_on 'Set up authenticator app'

        fill_in 'Current password', with: 'test'
        click_on 'Next'

        find('canvas').click
        secret = find('#qr-code-secret-overlay > span').text
        fill_in('securityCode', with: ROTP::TOTP.new(secret).now)
        click_on 'Set Up'
        expect(page).to have_text('Two-factor method has been configured successfully.')

        recovery_codes = find('div[data-test-id="recovery-codes"]').text.split("\n")

        expect(recovery_codes.length).to be(10)

        click_on "OK, I've saved my recovery codes"

        expect(page).to have_button('Regenerate Recovery Codes')

        # Logout
        find("[aria-label=\"Avatar (#{agent.fullname})\"]").click
        click_on 'Sign out'

        # Login
        fill_in 'Username / Email', with: agent.login
        fill_in 'Password', with: 'test'
        click_on 'Sign in'

        # Switch to recovery codes.
        click_on 'Try another method'
        click_on 'Or use one of your recovery codes.'
        fill_in('Recovery Code', with: recovery_codes[0])
        click_on('Sign in')
        expect(page).to have_current_route('/')
      end
    end
  end

  describe 'token handling' do
    let(:agent) { create(:admin) }

    it 'user can create and use a token' do
      go_to_personal_setting
      click_on 'Token Access'

      click_on 'New Personal Access Token'

      fill_in 'Name', with: 'Test Token'

      # Activate some permissions for the token
      find('span', text: 'Configure your system.').click
      find('span', text: 'Manage personal settings.').click

      click_on 'Create'
      wait_for_mutation('userCurrentAccessTokenAdd')

      expect(Token.last.name).to eq('Test Token')
      expect(Token.last.permissions.map(&:name)).to eq(%w[admin user_preferences])
      expect(Token.last.check?).to be(true)
    end
  end
end
