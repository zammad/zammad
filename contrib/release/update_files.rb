# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

if !Gem::Version.correct?(ARGV[0])
  puts 'Usage: update_files.rb new.semantic.version'
  exit 1
end

# New version
new_version = ARGV[0].chomp
(new_version_major, new_version_minor) = new_version.split('.')

# Previous stable version
previous_stable_version = `git tag | grep -v "-" | tail -n1`.chomp

# Write VERSION
Rails.root.join('VERSION').write("#{new_version}\n")

# Write CHANGELOG.md
changelog = <<~CHANGELOG
  # Change Log for Zammad #{new_version}

  - [Release notes](https://zammad.com/en/releases/#{new_version.tr('.', '-').sub(%r{-0$}, '')})
  - [Breaking changes](BREAKING_CHANGES.md##{new_version_major}#{new_version_minor})
  - [Implemented enhancements](https://github.com/zammad/zammad/issues?q=is%3Aclosed+milestone%3A#{new_version_major}.#{new_version_minor}+(-type%3ABug+AND+-label%3Abug))
  - [Closed bugs](https://github.com/zammad/zammad/issues?q=is%3Aclosed+milestone%3A#{new_version_major}.#{new_version_minor}+(type%3ABug+OR+label%3Abug))
  - [Full commit log](https://github.com/zammad/zammad/compare/#{previous_stable_version}...#{new_version})
  - [File tree](https://github.com/zammad/zammad/tree/#{new_version})
CHANGELOG

Rails.root.join('CHANGELOG.md').write(changelog)
