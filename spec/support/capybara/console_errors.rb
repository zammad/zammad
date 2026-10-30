# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Register the driven_by hooks first: their window resize creates the Playwright
#   page, so the subscription hook below never has to create one itself.
require_relative 'driven_by'

RSpec.configure do |config|
  config.before(:each, type: :system) do
    # Playwright has no log polling API - subscribe to the fresh page each example
    #   gets and collect for the after hook.
    @playwright_console_logs = console_logs = []

    subscribe = lambda { |pw_page|
      pw_page.on('console', lambda { |msg|
        level    = { 'error' => 'SEVERE', 'warning' => 'WARNING' }.fetch(msg.type, 'INFO')
        location = msg.location.presence&.then { |l| "#{l['url']} #{l['lineNumber']}:#{l['columnNumber']} " }
        console_logs << { level: level, message: "#{location}#{msg.text}" }
      })
      # Uncaught exceptions only fire 'pageerror' - mirror Chrome's SEVERE log format.
      pw_page.on('pageerror', lambda { |error|
        console_logs << { level: 'SEVERE', message: "Uncaught #{[error.name.presence, error.message].compact.join(': ')}" }
      })
    }

    page.driver.with_playwright_page do |pw_page|
      subscribe.call(pw_page)

      # A subscription is per page, so attach to pages opened later in the
      #   example as well (see the switch_to_window_index specs) - otherwise a
      #   JS error raised in a second tab passes this gate silently.
      pw_page.context.on('page', subscribe)
    end
  end

  config.after(:each, type: :system) do
    logs = @playwright_console_logs.to_a

    errors = logs.select { |m| m[:level] == 'SEVERE' && m[:message].match?(%r{EvalError|InternalError|RangeError|ReferenceError|SyntaxError|TypeError|URIError|E60(0|1)}) }
    # FIXME: Ignore certain unexplained JS errors that happen in some tests.
    #   - 1:37680 Uncaught TypeError: Cannot read properties of undefined (reading 'toUpperCase')
    errors = errors.reject { |e| e[:message].match?(%r{Uncaught TypeError: Cannot read properties of undefined \(reading 'toUpperCase'\)$}) }

    if errors.present?
      Rails.logger.error "JS ERRORS: #{errors.to_json}"
      errors.each do |error|
        puts "#{error[:message]}\n\n"
      end

      Rails.root.join('log/browser.log').write(logs.map { |l| "#{l[:level]}|#{l[:message]}" }.join("\n"))
    end

    expect(errors.length).to eq(0)
  end
end
