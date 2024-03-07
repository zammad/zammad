# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# load all core_ext extensions
Rails.root
  .glob('lib/core_ext/**/*.rb')
  .each do |file|
    require file
  end
