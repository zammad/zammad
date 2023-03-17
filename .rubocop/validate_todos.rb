#!/usr/bin/env ruby
# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'yaml'

# This script validates Rubocop's todo*.yml files and complains if there
#   are any exclude entries that point to nonexisting files.

obsolete_excludes = []

puts 'Checking for obsolete rubocop excludes...'

Dir.glob("#{__dir__}/todo*.yml").each do |f|
  YAML.load_file(f).each_value do |section|
    next if !section.key? 'Exclude'

    section['Exclude'].each do |file|
      next if file.include? '*'

      obsolete_excludes.push(file) if !File.exist? "#{__dir__}/../#{file}"
    end
  end
end

if obsolete_excludes.count.positive?
  puts 'Obsolete rubocop todo*.yml entries found for these files:'
  obsolete_excludes.sort.uniq.each do |file|
    puts " - #{file}"
  end
  exit false
end

puts 'done.'
