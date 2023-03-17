#!/usr/bin/env ruby
# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'yaml'
require 'resolv'
require 'fileutils'

#
# Configures the CI system
#   - (randomly) mysql or postgresql, if available
#   - (randomly) Redis or File as web socket session back end, if Redis is available
#   - (randomly) Memcached or File as Rails cache store, if Memcached is available
#   - Elasticsearch support, if available
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

  DB_SETTINGS_MAP = {
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
  }.freeze

  # Detect service availability based on host presence in network.
  def self.network_host_exists?(hostname)
    # GitLab used the /etc/hosts file if FF_NETWORK_PER_BUILD is not set.
    return true if File.foreach('/etc/hosts').any? { |l| l[hostname] }

    # Fall back to DNS lookup, also for GitHub
    !!Resolv::DNS.new.tap { |dns| dns.timeouts = 3 }.getaddress(hostname)
  rescue Resolv::ResolvError
    false
  end

  def self.configure_database # rubocop:disable Metrics/AbcSize

    if File.exist? File.join(__dir__, '../config/database.yml')
      puts "'config/database.yml' already exists and will not be changed."
      return
    end

    # Ruby 3.1 uses Psych 4 which made aliases support optional
    cnf = YAML.load_file(File.join(__dir__, '../config/database/database.yml'), aliases: true)
    cnf.delete('default')

    database = ENV['ENFORCE_DB_SERVICE'] || %w[postgresql mysql].shuffle.find do |db|
      network_host_exists?(db)
    end

    raise "Can't find any supported database." if database.nil?

    puts "Using #{database} as database service."

    # fetch DB settings from settings map and fallback to postgresql
    db_settings = DB_SETTINGS_MAP.fetch(database) { DB_SETTINGS_MAP['postgresql'] }

    %w[development test production].each do |environment|
      cnf[environment].merge!(db_settings)
    end

    File.write(File.join(__dir__, '../config/database.yml'), Psych.dump(cnf))
  end

  def self.configure_redis
    has_redis = network_host_exists?('redis')
    needs_redis = ENV['ENABLE_EXPERIMENTAL_MOBILE_FRONTEND'] == 'true'

    if needs_redis && !has_redis
      raise 'Redis was not found, but is required for ActionCable.'
    end

    if has_redis && [true, needs_redis].sample
      puts 'Using Redis as web socket session store and as adapter for ActionCable.'
      @env_file_content += "export REDIS_URL='redis://redis:6379'\n"
      return
    end

    puts 'Not using Redis.'
    @env_file_content += "unset REDIS_URL\n"
  end

  def self.configure_memcached
    if network_host_exists?('memcached') && [true, false].sample
      puts 'Using memcached as Rails cache store.'
      @env_file_content += "export MEMCACHE_SERVERS='memcached'\n"
      return
    end

    puts "Using Zammad's file store as Rails cache store."
    @env_file_content += "unset MEMCACHE_SERVERS\n"
  end

  def self.configure_elasticsearch
    if network_host_exists?('elasticsearch')
      puts 'Activating support for Elasticsearch.'
      @env_file_content += "export ES_URL='http://elasticsearch:9200'\n"
      return
    end

    puts 'Not using Elasticsearch.'
    @env_file_content += "unset ES_URL\n"
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
    puts 'ENABLING THE NEW EXPERIMENTAL MOBILE FRONTEND.' if ENV['ENABLE_EXPERIMENTAL_MOBILE_FRONTEND'] == 'true'
    configure_database
    configure_redis
    configure_memcached
    configure_elasticsearch
    write_env_file
  end
end

ConfigureEnvironment.run
