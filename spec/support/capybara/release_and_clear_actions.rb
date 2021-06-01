# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.configure do |config|
  config.after(:each, type: :system) do
    page.driver.browser.action.release_actions
    page.driver.browser.action.clear_all_actions
  end
end
