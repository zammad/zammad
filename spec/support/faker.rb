# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.configure do |config|
  config.after do
    Faker::UniqueGenerator.clear
  end
end
