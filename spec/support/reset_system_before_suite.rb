RSpec.configure do |config|
  config.before(:suite) do
    next if ENV['NO_RESET_BEFORE_SUITE']

    Rake::Task['zammad:db:reset'].invoke
  end
end
