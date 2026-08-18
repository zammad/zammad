# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Register the driven_by hooks first: their window resize creates the Playwright
#   page, so the hooks below never have to create one themselves. It also pins
#   the hook order the two after-hooks below rely on.
require_relative 'driven_by'

# Record a Playwright trace (per-action screenshots, console and network
#   timeline) for every example and keep it only on failure - far more
#   diagnostic than the plain failure screenshot. Inspect a trace locally with
#   `pnpm exec playwright show-trace <zip>` or at https://trace.playwright.dev.
#   Covers the default session only: `using_session` sessions run their own
#   browser contexts and stay untraced.
#
# Pending traces are written outside the CI artifact path, so only the ones kept
#   for a failure are uploaded.
PLAYWRIGHT_TRACE_PENDING_DIR = Rails.root.join('tmp/playwright-traces-pending')
PLAYWRIGHT_TRACE_KEEP_DIR    = Rails.root.join('tmp/playwright-traces')

# DOM snapshots additionally give the trace viewer its time travel - inspecting
#   the live DOM at every step - but they are captured per Playwright action, and
#   this driver's emulation layer issues several browser calls where Selenium
#   issues one (`Element#text` alone costs four). Measured on desktop specs they
#   cost 27-46% of runtime, against ~3% for the screenshots, so they are opt-in:
#   set PLAYWRIGHT_TRACE=full for a run that needs them.
PLAYWRIGHT_TRACE_SNAPSHOTS = ENV['PLAYWRIGHT_TRACE'] == 'full'

RSpec.configure do |config|
  config.before(:each, type: :system) do
    next if !page.driver.is_a?(Capybara::Playwright::Driver)

    page.driver.with_playwright_page do |pw_page|
      pw_page.context.tracing.start(screenshots: true, snapshots: PLAYWRIGHT_TRACE_SNAPSHOTS)
      @playwright_tracing_started = true
    end
  end

  # Stopping a trace needs a live page, so it has to happen before driven_by.rb
  #   tears the session down - after-hooks run in reverse definition order, and
  #   driven_by is required above, so this one runs first. Capturing is
  #   unconditional because whether the example failed is not settled yet.
  config.after(:each, type: :system) do |example|
    next if !@playwright_tracing_started

    @playwright_tracing_started = false
    @playwright_trace_path = PLAYWRIGHT_TRACE_PENDING_DIR.join("#{example.id.gsub(%r{[^\w-]+}, '_')}.zip")
    FileUtils.mkdir_p(PLAYWRIGHT_TRACE_PENDING_DIR)

    begin
      page.driver.with_playwright_page do |pw_page|
        pw_page.context.tracing.stop(path: @playwright_trace_path.to_s)
      end
    rescue => e
      # Never fail an example over trace bookkeeping (e.g. when the example
      #   itself quit the browser session).
      @playwright_trace_path = nil
      Rails.logger.error "Could not save the Playwright trace: #{e.message}"
    end
  end

  # append_after, so this runs after every other after-hook: the console error
  #   gate (console_errors.rb) fails the example from its own after-hook, and
  #   deciding any earlier would discard the trace for exactly those failures.
  config.append_after(:each, type: :system) do |example|
    next if @playwright_trace_path.nil?

    pending_path           = @playwright_trace_path
    @playwright_trace_path = nil

    next FileUtils.rm_f(pending_path) if example.exception.nil?

    FileUtils.mkdir_p(PLAYWRIGHT_TRACE_KEEP_DIR)
    FileUtils.mv(pending_path, PLAYWRIGHT_TRACE_KEEP_DIR.join(pending_path.basename))
  end
end
