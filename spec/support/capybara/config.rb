# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

Capybara.configure do |config|
  config.threadsafe            = true
  config.always_include_port   = true
  config.default_max_wait_time = 16
end
