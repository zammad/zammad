# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# automatically require all helpers in test/support
Dir[Rails.root.join('test/support/**/*.rb')].each { |f| require f }
