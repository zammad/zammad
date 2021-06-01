# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.configure do |config|
  config.around(:each, :time_zone) do |example|
    if example.metadata[:type] == :system
      old_tz = ENV['TZ']
      ENV['TZ'] = example.metadata[:time_zone]

      example.run
    else
      Time.use_zone(example.metadata[:time_zone]) { example.run }
    end
  ensure
    ENV['TZ'] = old_tz if example.metadata[:type] == :system
  end
end
