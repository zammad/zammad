# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'security keys setup', authenticated_as: :authenticate do
  let(:password_check) { true }
  let(:current_user)   { agent }

  def authenticate
    Setting.set('two_factor_authentication_method_security_keys', true)

    current_user
  end

  before do
    skip('Mocking of Web Authentication API is currently supported only in Chrome.') if Capybara.current_driver != :zammad_chrome
  end

  it 'sets up security keys method' do
    setup_security_keys_method(user: current_user, password_check: password_check)
  end
end

def mock_security_key
  options = Selenium::WebDriver::VirtualAuthenticatorOptions.new(protocol: :u2f, transport: :usb, resident_key: false,
                                                                 user_consenting: true, user_verification: true,
                                                                 user_verified: true)
  page.driver.browser.add_virtual_authenticator(options)
end

def setup_security_keys_method(user:, password_check:)
  in_modal do
    if password_check
      expect(page).to have_text('Set up two-factor authentication: Confirm Password')

      fill_in 'Password', with: user.password_plain

      click_on 'Next'
    end

    expect(page).to have_text('Set up two-factor authentication: Security Keys')

    click_on 'Set Up'

    expect(page).to have_text('Set up two-factor authentication: Security Key')

    fill_in 'Name for this security key', with: Faker::Lorem.unique.word

    mock_security_key

    click_on 'Next'

    expect(page).to have_text('Set up two-factor authentication: Save Codes')

    click_on "OK, I've saved my recovery codes"
  end

  expect(page).to have_no_css('.modal')
  expect(user.reload.two_factor_configured?).to be(true)
end
