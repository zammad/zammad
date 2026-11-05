# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'playwright/test'

# Elements are found like assistive technology finds them: by role and accessible name,
#   form fields by their label.
module PlaywrightNative
  module Page
    VIEWPORTS = {
      mobile:  { width: 390, height: 844 },
      tablet:  { width: 1020, height: 760 },
      desktop: { width: 1520, height: 1000 },
    }.freeze

    # The JavaScript errors that fail an example, the app's own included (E600, E601).
    JS_ERROR = %r{EvalError|InternalError|RangeError|ReferenceError|SyntaxError|TypeError|URIError|E60(0|1)}

    SCREENSHOT_DIR = Rails.root.join('tmp/screenshots')
    TRACE_DIR      = Rails.root.join('tmp/playwright-traces')

    # Like the page fixture of Playwright for JS and Python: a page in the example's own context.
    def page
      @page ||= browser_context.new_page
    end

    attr_reader :browser_context

    def open_desktop(route)
      page.goto("/desktop#{route}")
      wait_for_test_flag('applicationLoaded.loaded', skip_clearing: true)
    end

    def self.new_context(example)
      context = Browser.browser.new_context(
        baseURL:           AppServer.url,
        # The app server uses a self-signed certificate.
        ignoreHTTPSErrors: true,
        viewport:          VIEWPORTS.fetch(screen_size(example)),
        locale:            'en-US',
        # Without them copy buttons fail silently. Firefox rejects these names.
        permissions:       Browser.chromium? ? %w[clipboard-read clipboard-write] : [],
      )
      context.set_default_timeout(PLAYWRIGHT_TIMEOUT * 1000)
      context.tracing.start(screenshots: true, snapshots: true)
      context
    end

    def self.screen_size(example)
      example.metadata[:screen_size] || (example.metadata[:app] == :mobile ? :mobile : :desktop)
    end

    def self.collect_js_errors(context)
      [].tap do |errors|
        context.on('weberror', ->(web_error) { errors << "Uncaught #{[web_error.error.name.presence, web_error.error.message].compact.join(': ')}" })
        context.on('console', ->(message) { errors << message.text if message.type == 'error' })
      end
    end

    # Keeps a screenshot and the trace of a failed example, like Playwright's retain-on-failure.
    def self.close_context(context, example, page)
      file_name = example.id.delete_prefix('./').gsub(%r{[^\w-]+}, '_')

      if example.exception
        if page
          FileUtils.mkdir_p(SCREENSHOT_DIR)
          page.screenshot(path: SCREENSHOT_DIR.join("#{file_name}.png").to_s)
          puts "[Screenshot] #{SCREENSHOT_DIR.join("#{file_name}.png")}"
        end

        FileUtils.mkdir_p(TRACE_DIR)
        context.tracing.stop(path: TRACE_DIR.join("#{file_name}.zip").to_s)
        puts "[Trace] #{TRACE_DIR.join("#{file_name}.zip")}, open with: pnpm exec playwright show-trace <file>"
      else
        context.tracing.stop
      end
    ensure
      context.close
    end
  end
end

RSpec.configure do |config|
  config.include PlaywrightNative::Page, type: :playwright

  # have_text compares the whole text, so parts of it go through contain_text. playwright-ruby-client
  #   1.64 still matches a part with have_text as well (YusukeIwaki/playwright-ruby-client#401).
  config.include Playwright::Test::Matchers, type: :playwright

  config.before(:each, type: :playwright) do |example|
    Playwright::Test.expect_timeout = PLAYWRIGHT_TIMEOUT * 1000

    @browser_context = PlaywrightNative::Page.new_context(example)
    @js_errors       = PlaywrightNative::Page.collect_js_errors(@browser_context)
  end

  config.after(:each, type: :playwright) do
    # Not be_empty, Playwright's matchers take that name for elements.
    expect(@js_errors.grep(PlaywrightNative::Page::JS_ERROR)).to eq([])
  end

  # After every other after-hook, so the JavaScript error check above counts as a failure.
  config.append_after(:each, type: :playwright) do |example|
    PlaywrightNative::Page.close_context(@browser_context, example, @page)
  ensure
    PlaywrightNative::AppServer.finish_example
  end
end
