# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'yaml'
require 'resolv'

cnf = YAML.load_file(File.join(__dir__, '../../config/database/database.yml'))

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

puts "NOTICE: Found/selected #{database} Database Service"

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

File.open('config/database.yml', 'w') do |file|
  file.write(Psych.dump(cnf))
end
