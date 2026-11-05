# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Registers the browser drivers :zammad_chromium and :zammad_firefox, each with
#   a _mobile twin. Select one via TEST_BROWSER=chromium (default) or
#   TEST_BROWSER=firefox.
#
# Local (non-CI) runs launch the `playwright` package installed by `pnpm
#   install` (tracked in package.json, on the same minor version as Playwright::
#   COMPATIBLE_PLAYWRIGHT_VERSION so it stays in lockstep with the gem). The
#   package ships no browsers, so a one-time `pnpm playwright:install` is
#   required as well - without it the first driver call fails with
#   "Executable doesn't exist ... chrome-headless-shell". That script installs
#   Chromium only; the Firefox driver additionally needs a one-time
#   `pnpm exec playwright install firefox`. CI instead sets
#   PLAYWRIGHT_SERVER_URL to talk to the pre-built zammad-playwright service
#   container, so neither the local package nor its browsers are needed there.

require 'capybara/playwright'

# Capybara::Playwright::Driver#quit is private, so Session#quit's
#   `@driver.quit if @driver.respond_to?(:quit)` silently skips it and leaks the
#   session's node.js + browser processes until suite exit. Every place that
#   ends a session has to call this first (see driven_by.rb).
module PlaywrightSessionQuit
  def self.call(session)
    return if !session.instance_variable_get(:@driver).is_a?(Capybara::Playwright::Driver)

    session.driver.send(:quit)
  end
end

Capybara.register_driver(:zammad_chromium) do |app|
  build_playwright_driver(app)
end

Capybara.register_driver(:zammad_chromium_mobile) do |app|
  # User agent for Chrome on Android.
  build_playwright_driver(app, user_agent: 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Mobile Safari/537.36')
end

# Playwright's own patched Gecko build, not the branded Firefox release.
Capybara.register_driver(:zammad_firefox) do |app|
  build_playwright_driver(app, browser_type: :firefox)
end

Capybara.register_driver(:zammad_firefox_mobile) do |app|
  # User agent for Firefox on Android.
  build_playwright_driver(app, browser_type: :firefox, user_agent: 'Mozilla/5.0 (Android 13; Mobile; rv:109.0) Gecko/112.0 Firefox/112.0')
end

def build_playwright_driver(app, user_agent: nil, browser_type: :chromium)
  PlaywrightNative::Browser.assert_version_lockstep

  options = {
    browser_type:      browser_type,
    # The app is served over HTTPS by the :puma_wrapper Capybara server with
    #   self-signed certs from the 'localhost' gem. ignoreHTTPSErrors is part of
    #   the gem's NEW_PAGE_PARAMS (page_options.rb) and is forwarded to
    #   Playwright's browser.new_context, where it also covers WSS connections.
    ignoreHTTPSErrors: true,
    viewport:          { width: 1520, height: 1000 },
    locale:            'en-US',
    # Playwright contexts start with no permissions granted, so programmatic
    #   clipboard writes (e.g. copy-to-clipboard buttons) silently fail without
    #   this, breaking any spec that later reads the OS clipboard back (e.g. via
    #   a pasted keystroke).
    #   Chromium only - Firefox rejects these permission names outright.
    permissions:       browser_type == :chromium ? %w[clipboard-read clipboard-write] : [],
  }

  # The launch arguments are Chromium flags, so only Chromium gets them - and in
  #   both modes, otherwise local and CI browsers would launch differently.
  launch_options = browser_type == :chromium ? PlaywrightNative::Browser.chromium_launch_options : {}

  if ENV['PLAYWRIGHT_SERVER_URL'].present?
    # Remote browser server (CI): `playwright run-server` in the
    #   zammad-playwright service container, which launches a browser per
    #   connection with the launch options passed below; headless is its
    #   default. The context options above are applied client-side.
    options[:browser_server_endpoint_url] = PlaywrightNative::Browser.server_endpoint_url(launch_options)
  else
    # Local subprocess: the driver launches the browser itself, so the same
    #   launch options are passed straight through (BrowserOptions::LAUNCH_PARAMS).
    options[:playwright_cli_executable_path] = PlaywrightNative::Browser::CLI_PATH
    options[:headless] = ENV['TEST_BROWSER_HEADLESS'].present?
    options.merge!(launch_options)
  end

  options[:userAgent] = user_agent if user_agent.present?

  ENV['FAKE_LOGIN_USER_ID'] = nil
  ENV['FAKE_LOGIN_PENDING'] = nil

  Capybara::Playwright::Driver.new(app, **options)
end
