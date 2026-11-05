# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Specs of type :playwright drive the app with Playwright alone, like Playwright for JS and
#   Python do: one browser per process, a fresh browser context per example, the app
#   served from this process.
#
# Their port sits next to the one of the system specs (3001), so both can run in one process.
PLAYWRIGHT_APP_HOSTNAME = ENV['TEST_APP_HOSTNAME'] || (ENV['CI'].present? ? 'build' : 'localhost')
PLAYWRIGHT_APP_PORT     = ENV.fetch('TEST_APP_PORT', 3002).to_i

# Seconds for waits, actions and expectations.
PLAYWRIGHT_TIMEOUT = 16

RSpec.configure do |config|
  # They share the app's test setup with the system specs (set up system, login, jobs).
  config.define_derived_metadata(type: :system) { |metadata| metadata[:browser_app] = true }
  config.define_derived_metadata(type: :playwright) { |metadata| metadata[:browser_app] = true }
end
