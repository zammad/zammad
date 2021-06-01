# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.configure do |config|
  # make usage of time travel helpers possible
  config.include ActiveSupport::Testing::TimeHelpers

  # avoid stuck time issues
  config.after(:each) do
    travel_back
  end
end
