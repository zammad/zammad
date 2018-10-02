RSpec.configure do |config|

  config.around(:each, db_strategy: :truncation) do |example|
    self.use_transactional_tests = false
    example.run
    Rake::Task['zammad:db:reset'].execute
  end
end
