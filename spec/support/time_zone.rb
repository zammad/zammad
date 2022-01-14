# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.around(:each, :time_zone) do |example|
    if example.metadata[:type] == :system
      # RSpec System/Capybara tests use TZ variable to set timezone in browser
      old_tz = ENV['TZ']
      ENV['TZ'] = example.metadata[:time_zone]

      example.run
    else
      # Other RSpec tests run inside of the same process and don't take TZ into account.
      # Mocking time zone via Time object is enough
      Time.use_zone(example.metadata[:time_zone]) { example.run }
    end
  ensure
    ENV['TZ'] = old_tz if example.metadata[:type] == :system
  end
end
