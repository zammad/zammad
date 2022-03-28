# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

# automatically require all helpers in test/support
Dir[Rails.root.join('test/support/**/*.rb')].each { |f| require f }
