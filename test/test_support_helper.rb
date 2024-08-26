# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# automatically require all helpers in test/support
Rails.root.glob('test/support/**/*.rb').each { |f| require f }
