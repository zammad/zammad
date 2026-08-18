# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Registers a virtual U2F security key in the given browser session, so specs can
#   mock WebAuthn credentials. Selenium supports this natively, Playwright needs
#   raw CDP commands.
#
# A module function rather than an example-group helper, because the
#   two_factor_preference factory needs it too - and a factory receives its page
#   as a transient attribute, without access to the example's helpers.
#
# @example
#  VirtualAuthenticator.register(page)
#
module VirtualAuthenticator
  def self.register(page)
    driver = page.driver

    return register_via_selenium(driver) if driver.is_a?(Capybara::Selenium::Driver)

    register_via_cdp(driver)
  end

  def self.register_via_selenium(driver)
    options = Selenium::WebDriver::VirtualAuthenticatorOptions.new(protocol: :u2f, transport: :usb,
                                                                   resident_key: false, user_consenting: true,
                                                                   user_verification: true, user_verified: true)
    driver.browser.add_virtual_authenticator(options)
  end

  def self.register_via_cdp(driver)
    driver.with_playwright_page do |pw_page|
      cdp = pw_page.context.new_cdp_session(pw_page)
      cdp.send_message('WebAuthn.enable')

      # Mirrors the Selenium options above (user_consenting -> automaticPresenceSimulation).
      cdp.send_message('WebAuthn.addVirtualAuthenticator',
                       params: {
                         options: {
                           protocol:                    'u2f',
                           transport:                   'usb',
                           hasResidentKey:              false,
                           hasUserVerification:         true,
                           isUserVerified:              true,
                           automaticPresenceSimulation: true,
                         },
                       })
    end
  end
  private_class_method :register_via_selenium, :register_via_cdp
end
