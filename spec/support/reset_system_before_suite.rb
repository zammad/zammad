RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    Rails.application.load_seed
    Cache.clear
    Setting.reload
  end
end
