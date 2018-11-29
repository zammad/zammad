namespace :postgresql do
  task :setup do
    require 'bundler'
    Bundler.require(:default, :postgresql)
  end

  task :create_database => :setup do
    spec = CompositePrimaryKeys::ConnectionSpec['postgresql']
    ActiveRecord::Base.clear_all_connections!
    ActiveRecord::Base.establish_connection(spec.dup.merge('database' => 'postgres'))
    ActiveRecord::Base.connection.create_database(spec['database'])
    ActiveRecord::Base.clear_all_connections!
  end

  desc 'Build the Postgresql test database'
  task :build_database => :create_database do
    spec = CompositePrimaryKeys::ConnectionSpec['postgresql']
    ActiveRecord::Base.clear_all_connections!
    connection = ActiveRecord::Base.establish_connection(spec)

    schema = File.join(PROJECT_ROOT, 'test', 'fixtures', 'db_definitions', 'postgresql.sql')
    sql = File.read(schema)

    ActiveRecord::Base.connection.execute(sql)
    ActiveRecord::Base.clear_all_connections!
  end

  desc 'Drop the Postgresql test database'
  task :drop_database  => :setup do
    spec = CompositePrimaryKeys::ConnectionSpec['postgresql']
    ActiveRecord::Base.clear_all_connections!
    connection = ActiveRecord::Base.establish_connection(spec.merge('database' => 'postgres'))
    ActiveRecord::Base.connection.drop_database(spec['database'])
    ActiveRecord::Base.clear_all_connections!
  end

  desc 'Rebuild the PostgreSQL test database'
  task :rebuild_database => [:drop_database, :build_database]
end