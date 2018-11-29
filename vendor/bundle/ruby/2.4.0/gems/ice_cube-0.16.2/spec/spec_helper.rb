require "bundler/setup"
require 'ice_cube'

begin
  require 'simplecov'
  SimpleCov.start
rescue LoadError
  # okay
end

IceCube.compatibility = 12

DAY = Time.utc(2010, 3, 1)
WEDNESDAY = Time.utc(2010, 6, 23, 5, 0, 0)

WORLD_TIME_ZONES = [
  'America/Anchorage',  # -1000 / -0900
  'Europe/London',      # +0000 / +0100
  'Pacific/Auckland',   # +1200 / +1300
]

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  Dir[File.dirname(__FILE__) + '/support/**/*'].each { |f| require f }

  config.include WarningHelpers

  config.before :each do |example|
    if example.metadata[:requires_active_support]
      raise 'ActiveSupport required but not present' unless defined?(ActiveSupport)
    end
  end

  config.around :each do |example|
    if zone = example.metadata[:system_time_zone]
      orig_zone = ENV['TZ']
      ENV['TZ'] = zone
      example.run
      ENV['TZ'] = orig_zone
    else
      example.run
    end
  end

  config.around :each, expect_warnings: true do |example|
    capture_warnings do
      example.run
    end
  end
end
