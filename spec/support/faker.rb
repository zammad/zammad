# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.after do
    Faker::UniqueGenerator.clear
  end
end
