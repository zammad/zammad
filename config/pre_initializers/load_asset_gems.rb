# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Only load gems for asset compilation if they are needed to avoid
#   having unneeded runtime dependencies like NodeJS.
if ArgvHelper.argv.any? { |e| e.start_with? 'assets:' } || Rails.groups.exclude?('production')
  Bundler
    .load
    .current_dependencies
    .each do |dep|
      require dep.name if dep.groups.include?(:assets)
    end
end
