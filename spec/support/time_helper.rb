RSpec.configure do |config|
  # make usage of time travel helpers possible
  config.include ActiveSupport::Testing::TimeHelpers

  # avoid stuck time issues
  config.after(:each) do
    travel_back
  end
end
