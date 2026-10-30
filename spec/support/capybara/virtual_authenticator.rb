# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Registers a virtual U2F security key in the given browser session, so specs can
#   mock WebAuthn credentials. Playwright needs raw CDP commands for this, so it
#   works in Chromium only.
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
    page.driver.with_playwright_page do |pw_page|
      cdp = pw_page.context.new_cdp_session(pw_page)
      cdp.send_message('WebAuthn.enable')

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
end
