# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.after(:each, type: :system) do
    # PLAYWRIGHT PILOT: Selenium-only actions API; `page.driver.browser` is private
    #   on the Playwright driver and would raise NoMethodError.
    next if !page.driver.is_a?(Capybara::Selenium::Driver)
    next if !page.driver.browser.respond_to?(:action)

    page.driver.browser.action.release_actions
    page.driver.browser.action.clear_all_actions
  end
end
