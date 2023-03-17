# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.around(:each, :time_zone) do |example|
    # RSpec System/Capybara tests use TZ environment variable to set timezone in the browser.
    if example.metadata[:type] == :system
      old_tz = ENV['TZ']
      ENV['TZ'] = example.metadata[:time_zone]
    end

    # Other RSpec tests run inside the same process and don't take TZ variable into account.
    #   However, they should still have mocking of the test time zone for the Time object applied.
    Time.use_zone(example.metadata[:time_zone]) { example.run }
  ensure
    ENV['TZ'] = old_tz if example.metadata[:type] == :system
  end
end
