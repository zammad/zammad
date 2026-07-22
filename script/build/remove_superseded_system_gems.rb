#!/usr/bin/env ruby
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Removes default and bundled gems of the Ruby installation that are superseded by newer,
#   Bundler-managed versions from Gemfile.lock. These stale copies can never be loaded at
#   runtime, but cause false positives in container vulnerability scanners (#6258).

require 'bundler'
require 'rubygems/uninstaller'

locked_versions = Bundler::LockfileParser
  .new(File.read(File.expand_path('../../Gemfile.lock', __dir__)))
  .specs
  .to_h { |lockfile_spec| [lockfile_spec.name, lockfile_spec.version] }

superseded_specs = Gem::Specification.select do |installed_spec|
  locked_version = locked_versions[installed_spec.name]

  locked_version &&
    installed_spec.loaded_from.to_s.start_with?(Gem.default_dir) &&
    installed_spec.version < locked_version
end

superseded_specs.each do |spec|
  locked_version = locked_versions[spec.name]

  if spec.default_gem?
    puts "Removing default gem specification #{spec.full_name} (Gemfile.lock has #{locked_version})"
    File.delete(spec.loaded_from)
  else
    puts "Uninstalling bundled gem #{spec.full_name} (Gemfile.lock has #{locked_version})"
    Gem::Uninstaller.new(
      spec.name,
      version:     spec.version.to_s,
      install_dir: Gem.default_dir,
      executables: true,
      ignore:      true,
      force:       true
    ).uninstall
  end
end
