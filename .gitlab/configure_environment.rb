#!/usr/bin/env ruby
# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'yaml'
require 'resolv'
require 'fileutils'

#
# Configures the CI system
#   - either (randomly) mysql or postgresql, if it is available
#   - (randomly) Redis or File as web socket session back end, if Redis is available
#
# Database config happens directly in config/database.yml, other settings are written to
#   .gitlab/environment.env which must be sourced in the CI configuration.
#

class ConfigureEnvironment

  @env_file_content = <<~ENV_FILE_CONTENT
    #!/bin/bash
    FRESHENVFILE=fresh.env && test -f $FRESHENVFILE && source $FRESHENVFILE
    true
  ENV_FILE_CONTENT

  def self.configure_database # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    if File.exist? File.join(__dir__, '../config/database.yml')
      puts "'config/database.yml' already exists and will not be changed."
      return
    end

    cnf = YAML.load_file(File.join(__dir__, '../config/database/database.yml'))
    cnf.delete('default')

    database = ENV['ENFORCE_DB_SERVICE']

    # Lookup in /etc/hosts first: gitlab uses that if FF_NETWORK_PER_BUILD is not set.
    if !database
      hostsfile = '/etc/hosts'
      database  = %w[postgresql mysql].shuffle.find do |possible_database|
        File.foreach(hostsfile).any? { |l| l[possible_database] }
      end
    end

    # Lookup via DNS if needed: gitlab uses that if FF_NETWORK_PER_BUILD is enabled.
    if !database
      dns = Resolv::DNS.new
      dns.timeouts = 3
      database = %w[postgresql mysql].shuffle.find do |possible_database|
        # Perform a lookup of the database host to check if it is configured as a service.
        if dns.getaddress possible_database
          next possible_database
        end
      rescue Resolv::ResolvError
        # Ignore DNS lookup errors
      end
    end

    raise "Can't find any supported database." if database.nil?

    puts "Using #{database} as database service."

    db_settings_map = {
      'postgresql' => {
        'adapter'  => 'postgresql',
        'username' => 'zammad',
        'password' => 'zammad',
        'host'     => 'postgresql', # db alias from gitlab-ci.yml
      },
      'mysql'      => {
        'adapter'  => 'mysql2',
        'username' => 'root',
        'password' => 'zammad',
        'host'     => 'mysql', # db alias from gitlab-ci.yml
      }
    }

    # fetch DB settings from settings map and fallback to postgresql
    db_settings = db_settings_map.fetch(database) { db_settings_map['postgresql'] }

    %w[development test production].each do |environment|
      cnf[environment].merge!(db_settings)
    end

    File.write(File.join(__dir__, '../config/database.yml'), Psych.dump(cnf))
  end

  def self.configure_redis
    if ENV['REDIS_URL'].nil? || ENV['REDIS_URL'].empty? # rubocop:disable Rails/Blank
      if database_type == 'mysql'
        raise 'Redis was not found, but is required for ActionCable on MySQL based systems.'
      end

      puts 'Redis is not available, using File as web socket session store.'
      puts 'Redis is not available, using the PostgreSQL adapter for ActionCable.'
      return
    end
    if database_type == 'mysql' || [true, false].sample
      puts 'Using Redis as web socket session store.'
      puts 'Using the Redis adapter for ActionCable.'
      return
    end
    puts 'Using File as web socket session store.'
    puts 'Using the PostgreSQL adapter for ActionCable.'
    @env_file_content += "unset REDIS_URL\n"
  end

  def self.configure_memcached
    if ENV['MEMCACHE_SERVERS'].nil? || ENV['MEMCACHE_SERVERS'].empty? # rubocop:disable Rails/Blank
      puts 'Memcached is not available, using File as Rails cache store.'
      return
    end
    if [true, false].sample
      puts 'Using memcached as Rails cache store.'
      return
    end
    puts "Using Zammad's file store as Rails cache store."
    @env_file_content += "unset MEMCACHE_SERVERS\n"
  end

  # Since configure_database skips if database.yml already exists, check the
  #   content of that file to reliably determine the database type in all cases.
  def self.database_type
    database = File.read(File.join(__dir__, '../config/database.yml')).match(%r{^\s*adapter:\s*(mysql|postgresql)})[1]
    if !database
      raise 'Could not determine database type, cannot setup cable.yml'
    end

    database
  end

  def self.write_env_file
    File.write(File.join(__dir__, 'environment.env'), @env_file_content)
  end

  def self.run
    configure_database
    configure_redis
    configure_memcached
    write_env_file
  end
end

ConfigureEnvironment.run
