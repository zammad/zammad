namespace :mysql do
  task :setup do
    require 'bundler'
    Bundler.require(:default, :mysql)
  end

  task :create_database => :setup do
    spec = CompositePrimaryKeys::ConnectionSpec['mysql']
    ActiveRecord::Base.clear_all_connections!
    new_spec = spec.dup
    new_spec.delete('database')
    connection = ActiveRecord::Base.establish_connection(new_spec)
    ActiveRecord::Base.connection.create_database(spec['database'])
    ActiveRecord::Base.clear_all_connections!
  end

  desc 'Build the MySQL test database'
  task :build_database => [:create_database] do
    path = File.join(PROJECT_ROOT, 'test', 'fixtures', 'db_definitions', 'mysql.sql')
    sql = File.open(path, 'rb') do |file|
      file.read
    end

    spec = CompositePrimaryKeys::ConnectionSpec['mysql']
    connection = ActiveRecord::Base.establish_connection(spec)
    sql.split(";").each do |statement|
      ActiveRecord::Base.connection.execute(statement) unless statement.strip.length == 0
    end
  end

  desc 'Drop the MySQL test database'
  task :drop_database => :setup do
    spec = CompositePrimaryKeys::ConnectionSpec['mysql']
    connection = ActiveRecord::Base.establish_connection(spec)
    ActiveRecord::Base.connection.drop_database(spec['database'])
  end

  desc 'Rebuild the MySQL test database'
  task :rebuild_database => [:drop_database, :build_database]
end
