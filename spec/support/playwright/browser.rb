# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'playwright'

module PlaywrightNative
  # One browser per process, launched on first use. TEST_BROWSER=firefox switches from
  #   Chromium. Locally the `playwright` package of `pnpm install` launches it, CI sets
  #   PLAYWRIGHT_SERVER_URL to the browser server of the zammad-playwright service container.
  module Browser
    CLI_PATH = Rails.root.join('node_modules/.bin/playwright').to_s

    def self.browser
      @browser ||= begin
        assert_version_lockstep

        if ENV['PLAYWRIGHT_SERVER_URL'].present?
          @execution = Playwright.connect_to_browser_server(server_endpoint_url(launch_options), browser_type: type)
          @execution.browser
        else
          @execution = Playwright.create(playwright_cli_executable_path: CLI_PATH)
          @execution.playwright.public_send(type).launch(headless: ENV['TEST_BROWSER_HEADLESS'].present?, **launch_options)
        end
      end
    end

    def self.type
      ENV.fetch('TEST_BROWSER', 'chromium')
    end

    def self.chromium?
      type == 'chromium'
    end

    def self.launch_options
      chromium? ? chromium_launch_options : {}
    end

    # The app's self-signed certificates are covered by the context's ignoreHTTPSErrors for
    #   page traffic, but something browser-side still validates them once per page and
    #   floods the log with "SSL alert number 46". The remote debugging port gives a live view
    #   of the headless browser in DevTools. It is opt-in: once the port is taken on 127.0.0.1
    #   and ::1, the next browser launch hangs until it times out.
    def self.chromium_launch_options
      args = ['--ignore-certificate-errors']
      args << "--remote-debugging-port=#{ENV['PLAYWRIGHT_REMOTE_DEBUGGING_PORT']}" if ENV['PLAYWRIGHT_REMOTE_DEBUGGING_PORT'].present?

      { args: args }
    end

    def self.stop
      @execution&.stop
      @execution = @browser = nil
    end

    # The browser server has no launch options parameter, but reads them from the endpoint's
    #   `launch-options` query. It honors args only when started with `--unsafe`, see services.yml.
    def self.server_endpoint_url(launch_options)
      url = ENV['PLAYWRIGHT_SERVER_URL']
      return url if launch_options.blank?

      separator = url.include?('?') ? '&' : '?'

      "#{url}#{separator}launch-options=#{CGI.escape(launch_options.to_json)}"
    end

    # The playwright npm package must stay in lockstep with the playwright-ruby-client gem,
    #   or the two protocol sides drift apart silently. Local runs and CI are provisioned
    #   from separate pins (package.json vs the PLAYWRIGHT_VERSION CI variable), so both are
    #   checked against the gem. Only major.minor has to match, like Playwright's own server
    #   handshake: the gem is released per minor version, the npm package and the server
    #   image get patch releases in between.
    def self.assert_version_lockstep
      expected = Playwright::COMPATIBLE_PLAYWRIGHT_VERSION
      minor    = ->(version) { version.to_s.split('.').first(2).join('.') }

      package_json = JSON.parse(Rails.root.join('package.json').read)
      pins = { 'package.json' => package_json.dig('devDependencies', 'playwright') || package_json.dig('dependencies', 'playwright') }
      pins['PLAYWRIGHT_VERSION'] = ENV['PLAYWRIGHT_VERSION'] if ENV['PLAYWRIGHT_VERSION'].present?

      drifted = pins.reject { |_source, pin| minor.call(pin) == minor.call(expected) }
      return if drifted.none?

      raise "playwright version drift: the playwright-ruby-client gem needs #{minor.call(expected)}.x, but " \
            "#{drifted.map { |source, pin| "#{source} has #{pin ? pin.inspect : 'no playwright entry'}" }.join(', ')}. " \
            'Keep the package.json devDependency, the PLAYWRIGHT_VERSION CI variable and the gem in lockstep.'
    end
  end
end

RSpec.configure do |config|
  config.after(:suite) do
    PlaywrightNative::Browser.stop
  end
end
