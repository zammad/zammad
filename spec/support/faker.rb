# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.configure do |config|
  config.after(:each) do
    Faker::UniqueGenerator.clear
  end
end
