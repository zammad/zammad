#!/usr/bin/env ruby
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Dumps and restores the database of the current RAILS_ENV, which allows the CI jobs to
#   restore a prepared database instead of running the migrations and seeds again.
#
# Usage: .gitlab/database.rb dump|restore
#
# Exits with 1 if the database cannot be dumped or restored, so that the caller can fall
#   back to `rake zammad:db:init`.

require 'fileutils'
require 'yaml'

REQUIRED_COMMANDS = %w[psql pg_dump pg_restore createdb].freeze
DUMP_DIRECTORY = ENV.fetch('CI_DATABASE_DUMP_DIRECTORY', 'tmp/database_dumps')
ENVIRONMENT = ENV.fetch('RAILS_ENV', 'test')

def database_config
  config = YAML.load_file('config/database.yml', aliases: true)[ENVIRONMENT]

  abort "ERROR: no database configuration found for '#{ENVIRONMENT}'." if config.nil?

  # pg_dump and pg_restore take these from the environment.
  ENV['PGHOST']     = config['host'] if config['host']
  ENV['PGUSER']     = config['username'] if config['username']
  ENV['PGPASSWORD'] = config['password'] if config['password']

  config
end

def dump_file
  File.join(DUMP_DIRECTORY, "#{ENVIRONMENT}.dump")
end

def run(*command)
  return true if system(*command)

  warn "Command failed: #{command.join(' ')}"
  false
end

# The client tools must match the server version: a newer pg_dump writes settings into the
#   dump which an older server does not understand. Use the matching versioned binaries if
#   installed (see docker/zammad-ci), otherwise whatever the PATH provides.
def client_command(command)
  versioned = "/usr/lib/postgresql/#{server_major_version}/bin/#{command}"

  File.executable?(versioned) ? versioned : command
end

def server_major_version
  @server_major_version ||= `psql --dbname postgres --tuples-only --no-align --command "SHOW server_version_num"`.to_i / 10_000
end

def dump(database)
  FileUtils.mkdir_p(DUMP_DIRECTORY)

  puts "Dumping the '#{database}' database to #{dump_file}…"

  run(client_command('pg_dump'), '--format=custom', '--file', dump_file, database)
end

def restore(database)
  # Dumps are only shared inside a pipeline, as migrations and seeds may have changed.
  if !File.exist?(dump_file)
    puts "No database dump found at #{dump_file}."
    return false
  end

  puts "Restoring the '#{database}' database from #{dump_file}…"

  # Create the database if it does not exist yet. An already existing database is reset by
  #   pg_restore itself, which also works while it has open connections (unlike dropdb).
  system(client_command('createdb'), database, out: File::NULL, err: File::NULL)

  run(client_command('pg_restore'), '--clean', '--if-exists', '--jobs=4', '--dbname', database, dump_file)
end

mode = ARGV[0]
abort 'Usage: .gitlab/database.rb dump|restore' if !%w[dump restore].include?(mode) # rubocop:disable Rails/NegateInclude

REQUIRED_COMMANDS.each do |command|
  next if system("command -v #{command} > /dev/null 2>&1")

  puts "#{command} is not available, skipping the database #{mode}."

  # A missing dump is not an error, the jobs then initialize the database themselves.
  exit mode == 'dump' ? 0 : 1
end

exit 1 if !send(mode, database_config['database'])
