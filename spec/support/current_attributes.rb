# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  # clear ActiveSupport::CurrentAttributes caches
  config.after do
    ActiveSupport::CurrentAttributes.clear_all
  end
end
