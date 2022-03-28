# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

# load all core_ext extensions
Dir.glob(Rails.root.join('lib/core_ext/**/*')).each do |file|
  if File.file?(file)
    require file
  end
end
