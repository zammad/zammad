namespace :sqlite do
  task :setup do
    require 'bundler'
    Bundler.require(:default, :sqlite)
  end

  desc 'Build the sqlite test database'
  task :build_database => :setup do
    spec = CompositePrimaryKeys::ConnectionSpec['sqlite']
    schema = File.join(PROJECT_ROOT, 'test', 'fixtures', 'db_definitions', 'sqlite.sql')
    FileUtils.mkdir_p(File.dirname(spec['database']))
    cmd = "sqlite3 #{spec['database']} < #{schema}"
    puts cmd
    sh %{ #{cmd} }
  end

  desc 'Drop the sqlite test database'
  task :drop_database => :setup do
    spec = CompositePrimaryKeys::ConnectionSpec['sqlite']
    sh %{ rm -f #{spec['database']} }
  end

  desc 'Rebuild the sqlite test database'
  task :rebuild_database => [:drop_database, :build_database]
end
