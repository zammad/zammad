# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# load all core_ext extensions
Rails.root.glob('lib/core_ext/**/*.rb').each do |file|
  if File.file?(file)
    require file
  end
end
