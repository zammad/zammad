#!/usr/bin/env ruby
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Converts all package definitions in YAML form found next to this script to the
# JSON based .zpm format, written to a file of the same base name. The content of
# all entries in "files" is transcoded to base64.
#
#   ruby yaml_to_zpm.rb
#
#   ZammadTestA-1.0.0.yaml -> ZammadTestA-1.0.0.zpm

require 'base64'
require 'json'
require 'yaml'

def convert(source, target)
  package = YAML.safe_load_file(source, aliases: true)

  raise "Expected a YAML mapping as package definition in #{source}." if !package.is_a?(Hash)

  Array(package['files']).each do |file|
    next if !file.is_a?(Hash) || !file.key?('content')

    file['encode'] = 'base64'
    file['content'] = Base64.strict_encode64(file['content'].to_s)
  end

  File.write(target, "#{JSON.pretty_generate(package)}\n")
end

sources = Dir.glob('*.{yaml,yml}', base: __dir__).sort

raise 'No YAML package definitions found.' if sources.empty?

sources.each do |source|
  target = "#{File.basename(source, '.*')}.zpm"

  convert(File.join(__dir__, source), File.join(__dir__, target))

  puts "#{source} -> #{target}"
end
