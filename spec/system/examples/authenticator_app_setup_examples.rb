# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rotp'

RSpec.shared_examples 'authenticator app setup' do
  let(:password_check) { true }

  it 'sets up authenticator app method with recovery codes' do
    Setting.set('two_factor_authentication_recovery_codes', true)
    setup_authenticator_app_method(user: agent, password_check: password_check, expect_recovery_codes: true)
  end

  it 'sets up authenticator app method without recovery codes' do
    Setting.set('two_factor_authentication_recovery_codes', false)
    setup_authenticator_app_method(user: agent, password_check: password_check, expect_recovery_codes: false)
  end
end

def setup_authenticator_app_method(user:, password_check:, expect_recovery_codes: false)
  in_modal do
    if password_check
      expect(page).to have_text('Set up two-factor authentication: Password')

      fill_in 'Password', with: password_check

      click_button 'Next'
    end

    expect(page).to have_text('Set up two-factor authentication: Authenticator App')

    click '.qr-code-canvas'

    secret = find('.secret').text
    security_code = ROTP::TOTP.new(secret).now

    fill_in 'Security Code', with: security_code

    click_button 'Set Up'

    if expect_recovery_codes
      any_code = user.two_factor_preferences.recovery_codes.configuration[:codes].sample

      expect(page).to have_text('Set up two-factor authentication: Recovery Codes')
      expect(page).to have_text(any_code)
      click_button "OK, I've saved my recovery codes"
    end
  end

  expect(page).to have_no_css('.modal')
  expect(user.two_factor_configured?).to be(true)
end
