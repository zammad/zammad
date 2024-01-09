# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
  if password_check
    in_modal do
      expect(page).to have_text('Set up two-factor authentication: Confirm Password')

      fill_in 'Password', with: password_check

      click_on 'Next'
    end
  end

  in_modal do
    expect(page).to have_text('Set up two-factor authentication: Authenticator App')

    click '.qr-code-canvas'

    secret = find('.secret').text
    security_code = ROTP::TOTP.new(secret).now

    fill_in 'Security Code', with: security_code

    click_on 'Set Up'
  end

  if expect_recovery_codes
    in_modal do
      stored_codes_amount    = user.two_factor_preferences.recovery_codes.configuration[:codes].count
      displayed_codes_amount = find('.two-factor-auth code').text.tr("\n", ' ').split.count

      expect(page).to have_text('Set up two-factor authentication: Save Codes')
      expect(stored_codes_amount).to eq(displayed_codes_amount)

      click_on "OK, I've saved my recovery codes"
    end
  end

  expect(page).to have_no_css('.modal')
  expect(user.reload.two_factor_configured?).to be(true)
end
