# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
