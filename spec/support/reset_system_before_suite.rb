RSpec.configure do |config|
  config.before(:suite) do
    Rake::Task['zammad:db:reset'].invoke
  end
end
