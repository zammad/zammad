# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# automatically require all helpers in test/support
Dir[Rails.root.join('test/support/**/*.rb')].sort.each { |f| require f }
