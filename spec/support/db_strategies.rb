RSpec.configure do |config|

  config.around(:each, db_strategy: :reset) do |example|
    self.use_transactional_tests = false
    example.run
    Rake::Task['zammad:db:reset'].reenable
    Rake::Task['zammad:db:reset'].invoke
  end
end
