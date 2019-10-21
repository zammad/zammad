RSpec.configure do |config|
  config.around(:each, :time_zone) do |example|
    old_tz = ENV['TZ']
    ENV['TZ'] = example.metadata[:time_zone]

    example.run
  ensure
    ENV['TZ'] = old_tz
  end
end
