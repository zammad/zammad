require 'yaml'

cnf = YAML.load_file(File.join(__dir__, '../../config/database/database.yml'))

cnf.delete('default')

hostsfile = '/etc/hosts'
database  = %w[postgresql mysql].find do |possible_database|
  File.foreach(hostsfile).any? { |l| l[possible_database] }
end

raise "Can't find any supported database in #{hostsfile}." if database.nil?

db_settings_map = {
  'postgresql' => {
    'adapter'  => 'postgresql',
    'username' => 'zammad',
    'password' => 'zammad',
    'host'     => 'postgresql', # db alias from gitlab-ci.yml
  },
  'mysql' => {
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
