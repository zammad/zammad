# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.around(:each, :time_zone) do |example|
    old_tz = ENV['TZ']

    # Rails' Time.zone does not reach Ruby's own local Time, gems built on it,
    #   or the browser in system specs, which all follow TZ instead.
    ENV['TZ'] = example.metadata[:time_zone]

    Time.use_zone(example.metadata[:time_zone]) { example.run }
  ensure
    ENV['TZ'] = old_tz
  end
end
