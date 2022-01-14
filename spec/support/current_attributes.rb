# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  # clear ActiveSupport::CurrentAttributes caches
  config.after do
    ActiveSupport::CurrentAttributes.clear_all
  end
end
