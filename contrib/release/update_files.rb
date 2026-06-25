# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'yaml'

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

  - [Release notes](https://zammad.com/en/product/releases/#{new_version.tr('.', '-').sub(%r{-0$}, '')})
  - [Breaking changes](BREAKING_CHANGES.md##{new_version_major}#{new_version_minor})
  - [Implemented enhancements](https://github.com/zammad/zammad/issues?q=is%3Aclosed+milestone%3A#{new_version_major}.#{new_version_minor}+(-type%3ABug+AND+-label%3Abug))
  - [Closed bugs](https://github.com/zammad/zammad/issues?q=is%3Aclosed+milestone%3A#{new_version_major}.#{new_version_minor}+(type%3ABug+OR+label%3Abug))
  - [Full commit log](https://github.com/zammad/zammad/compare/#{previous_stable_version}...#{new_version})
  - [File tree](https://github.com/zammad/zammad/tree/#{new_version})
CHANGELOG

Rails.root.join('CHANGELOG.md').write(changelog)

# Update publiccode.yml
publiccode_path = Rails.root.join('publiccode.yml')
publiccode_content = File.read(publiccode_path)

# Update version and release date
publiccode_content.gsub!(%r{^softwareVersion: .*$}, "softwareVersion: \"#{new_version}\"")
publiccode_content.gsub!(%r{^releaseDate: .*$}, "releaseDate: \"#{Time.zone.today.strftime('%Y-%m-%d')}\"")

# Update available languages from locales.yml
locales_config = YAML.load_file(Rails.root.join('config/locales.yml'))
available_languages = locales_config
  .select { |locale| locale['active'] }
  .map { |locale| locale['alias'].presence || locale['locale'].split('-').first.downcase }
  .uniq
  .sort

# Format languages as YAML list and replace in content
languages_yaml = available_languages.map { |lang| "    - \"#{lang}\"" }.join("\n")
publiccode_content.gsub!(%r{  availableLanguages:\n(?:    - .*\n)+}, "  availableLanguages:\n#{languages_yaml}\n")

# Write back to file
File.write(publiccode_path, publiccode_content)
