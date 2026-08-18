# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# THROWAWAY PILOT: registers :zammad_playwright (+ _mobile) alongside the
# Selenium drivers. Select via SELENIUM_BROWSER=playwright.
#
# Local (non-CI) runs launch the `playwright` package installed by `pnpm
#   install` (tracked in package.json, pinned to Playwright::
#   COMPATIBLE_PLAYWRIGHT_VERSION so it stays in lockstep with the gem). The
#   package ships no browsers, so a one-time `pnpm playwright:install` is
#   required as well - without it the first driver call fails with
#   "Executable doesn't exist ... chrome-headless-shell". CI instead sets
#   PLAYWRIGHT_SERVER_URL to talk to the pre-built zammad-playwright service
#   container, so neither the local package nor its browsers are needed there.

require 'capybara/playwright'

PLAYWRIGHT_CLI_PATH = Rails.root.join('node_modules/.bin/playwright').to_s

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

Capybara.register_driver(:zammad_playwright) do |app|
  build_playwright_driver(app)
end

Capybara.register_driver(:zammad_playwright_mobile) do |app|
  # Same UA string as :zammad_chrome_mobile.
  build_playwright_driver(app, user_agent: 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Mobile Safari/537.36')
end

# The playwright npm package must stay in lockstep with the
#   playwright-ruby-client gem, or the two protocol sides drift apart silently.
#   Local runs and CI are provisioned from separate pins (package.json vs the
#   PLAYWRIGHT_VERSION CI variable), so verify both against the gem before
#   starting a browser.
def assert_playwright_version_lockstep
  expected = Playwright::COMPATIBLE_PLAYWRIGHT_VERSION

  # The package.json pin provisions local runs and is always checked - a missing
  #   entry means there is nothing to launch, so it must not pass as "no drift".
  #   PLAYWRIGHT_VERSION provisions the browser server and only exists in CI
  #   (services.yml), so it is checked when set.
  package_json = JSON.parse(Rails.root.join('package.json').read)
  pins = { 'package.json' => package_json.dig('devDependencies', 'playwright') || package_json.dig('dependencies', 'playwright') }
  pins['PLAYWRIGHT_VERSION'] = ENV['PLAYWRIGHT_VERSION'] if ENV['PLAYWRIGHT_VERSION'].present?

  drifted = pins.reject { |_source, pin| pin == expected }
  return if drifted.none?

  raise "playwright version drift: the playwright-ruby-client gem needs #{expected}, but " \
        "#{drifted.map { |source, pin| "#{source} has #{pin ? pin.inspect : 'no playwright entry'}" }.join(', ')}. " \
        'Keep the package.json devDependency, the PLAYWRIGHT_VERSION CI variable and the gem in lockstep.'
end

# Chromium launch arguments, applied in both modes so local and CI browsers are
#   launched alike. The self-signed certs of the :puma_wrapper Capybara server
#   are covered for page/WSS traffic by the context's ignoreHTTPSErrors, but
#   something browser-side still validates them once per example and floods the
#   log with "SSL alert number 46" - the Selenium lanes pass the same flag for
#   the same reason.
PLAYWRIGHT_LAUNCH_OPTIONS = { args: ['--ignore-certificate-errors'] }.freeze

# `connect_to_browser_server` has no launch-option parameter, but the server
#   reads them from the endpoint's `launch-options` query (or an equivalent
#   header). It only honors args when started with `--unsafe`, see services.yml.
def playwright_server_endpoint_url
  url       = ENV['PLAYWRIGHT_SERVER_URL']
  separator = url.include?('?') ? '&' : '?'

  "#{url}#{separator}launch-options=#{CGI.escape(PLAYWRIGHT_LAUNCH_OPTIONS.to_json)}"
end

def build_playwright_driver(app, user_agent: nil)
  assert_playwright_version_lockstep

  options = {
    browser_type:      :chromium,
    # The app is served over HTTPS by the :puma_wrapper Capybara server with
    #   self-signed certs from the 'localhost' gem. ignoreHTTPSErrors is part of
    #   the gem's NEW_PAGE_PARAMS (page_options.rb) and is forwarded to
    #   Playwright's browser.new_context, where it also covers WSS connections.
    ignoreHTTPSErrors: true,
    # Replaces browser.manage.window.resize_to for the default desktop size.
    viewport:          { width: 1520, height: 1000 },
    locale:            'en-US',
    # Selenium/chromedriver setups commonly relax clipboard permissions so
    #   navigator.clipboard just works. Playwright contexts start with no
    #   permissions granted, so programmatic clipboard writes (e.g. copy-to-
    #   clipboard buttons) silently fail without this, breaking any spec that
    #   later reads the OS clipboard back (e.g. via a pasted keystroke).
    permissions:       %w[clipboard-read clipboard-write],
  }

  if ENV['PLAYWRIGHT_SERVER_URL'].present?
    # Remote browser server (CI): `playwright run-server` in the
    #   zammad-playwright service container, which launches a browser per
    #   connection with the launch options passed below; headless is its
    #   default. The context options above are applied client-side.
    options[:browser_server_endpoint_url] = playwright_server_endpoint_url
  else
    # Local subprocess: the driver launches the browser itself, so the same
    #   launch options are passed straight through (BrowserOptions::LAUNCH_PARAMS).
    options[:playwright_cli_executable_path] = PLAYWRIGHT_CLI_PATH
    options[:headless] = ENV['SELENIUM_BROWSER_HEADLESS'].present?
    options.merge!(PLAYWRIGHT_LAUNCH_OPTIONS)
  end

  options[:userAgent] = user_agent if user_agent.present?

  ENV['FAKE_SELENIUM_LOGIN_USER_ID'] = nil
  ENV['FAKE_SELENIUM_LOGIN_PENDING'] = nil

  Capybara::Playwright::Driver.new(app, **options)
end
