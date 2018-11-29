namespace :sqlserver do
  task :setup do
    require 'bundler'
    Bundler.require(:default, :sqlserver)
  end

  task :create_database => :setup do
    spec = CompositePrimaryKeys::ConnectionSpec['sqlserver']
    database = spec.delete('database')
    ActiveRecord::Base.clear_all_connections!

    ActiveRecord::Base.establish_connection(spec)
    ActiveRecord::Base.connection.execute("CREATE DATABASE [#{database}]")
    ActiveRecord::Base.clear_all_connections!
  end

  task :build_database => :create_database do
    spec = CompositePrimaryKeys::ConnectionSpec['sqlserver']
    ActiveRecord::Base.establish_connection(spec)

    schema = File.join(PROJECT_ROOT, 'test', 'fixtures', 'db_definitions', 'sqlserver.sql')
    sql = File.read(schema)
    ActiveRecord::Base.connection.execute(sql)
    ActiveRecord::Base.clear_all_connections!
  end

  desc 'Drop the SQL Server test database'
  task :drop_database => :setup do
    spec = CompositePrimaryKeys::ConnectionSpec['sqlserver']
    ActiveRecord::Base.clear_all_connections!
    ActiveRecord::Base.establish_connection(spec)
    database = spec.delete('database')
    ActiveRecord::Base.connection.execute(<<-SQL)
      USE master;
      ALTER DATABASE [#{database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
      DROP DATABASE [#{database}];
    SQL
    ActiveRecord::Base.clear_all_connections!
  end

  desc 'Rebuild the SQL Server test database'
  task :rebuild_database => [:drop_database, :build_database]
end
