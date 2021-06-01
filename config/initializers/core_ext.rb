# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# load all core_ext extensions
Dir.glob( Rails.root.join('lib/core_ext/**/*') ).sort.each do |file|
  if File.file?(file)
    require file
  end
end
