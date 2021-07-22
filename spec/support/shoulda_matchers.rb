# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
