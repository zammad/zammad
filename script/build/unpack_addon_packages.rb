#!/usr/bin/env ruby
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Unpacks all addon package files into the application source tree:
# - packages/install/*.zpm:   all files, the packages are registered in the database on container start.
# - packages/uninstall/*.zpm: all files, so that the down migrations can run on container start.
# The .zpm files stay in place, they are processed by the container init.
# Runs during the container image build, before assets:precompile - without a database.

require 'base64'
require 'fileutils'
require 'json'

ROOT_DIR = File.expand_path('../..', __dir__)

def read_packages(directory)
  Dir[File.join(ROOT_DIR, directory, '*.zpm')].map do |zpm_file|
    JSON.parse(File.read(zpm_file)).merge('zpm_file' => zpm_file)
  end
end

def locations(packages)
  packages.flat_map { |package| package['files'].map { |file| file['location'] } }
end

def unpack(package)
  puts "Unpacking #{package['name']}-#{package['version']} (#{File.basename(package['zpm_file'])})..."

  package['files'].each do |file|
    location = file['location']
    raise "Not allowed file location: #{location}!" if location.include?('..') || location.start_with?('/')

    path = File.join(ROOT_DIR, location)
    FileUtils.mkdir_p(File.dirname(path))
    File.binwrite(path, Base64.decode64(file['content']))
    File.chmod((file['permission'] || '644').to_s.to_i(8), path)
  end
end

install_packages   = read_packages('packages/install')
uninstall_packages = read_packages('packages/uninstall')

if install_packages.empty? && uninstall_packages.empty?
  puts 'No addon packages found in packages/install/ or packages/uninstall/, skipping.'
  exit 0
end

# This script runs without ActiveSupport, so Array#pluck is not available.
conflicts = install_packages.map { |package| package['name'] } & uninstall_packages.map { |package| package['name'] } # rubocop:disable Rails/Pluck
raise "Packages staged for both installation and uninstallation: #{conflicts.join(', ')}!" if conflicts.any?

# Files of outgoing packages stay in the image for their down migrations. They must not
#   overwrite files of incoming packages, so the build fails instead of producing an ambiguous image.
overlapping = locations(install_packages) & locations(uninstall_packages)
raise "Files provided by packages staged for both installation and uninstallation: #{overlapping.join(', ')}!" if overlapping.any?

(install_packages + uninstall_packages).each { |package| unpack(package) }

puts 'done.'
