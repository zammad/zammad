namespace :oracle do
  task :setup do
    require 'bundler'
    Bundler.require(:default, :oracle)
  end

  desc 'Build the Oracle test database'
  task :build_database => :setup do
    spec = CompositePrimaryKeys::ConnectionSpec['oracle']
    ActiveRecord::Base.clear_all_connections!
    ActiveRecord::Base.establish_connection(spec)

    schema = File.join(PROJECT_ROOT, 'test', 'fixtures', 'db_definitions', 'oracle.sql')
    sql = File.read(schema)

    sql.split(';').each do |command|
      ActiveRecord::Base.connection.execute(command) unless command.blank?
    end

    ActiveRecord::Base.clear_all_connections!
  end

  desc 'Drop the Oracle test database'
  task :drop_database => :setup do
    spec = CompositePrimaryKeys::ConnectionSpec['oracle']
    ActiveRecord::Base.clear_all_connections!
    ActiveRecord::Base.establish_connection(spec)

    schema = File.join(PROJECT_ROOT, 'test', 'fixtures', 'db_definitions', 'oracle.drop.sql')
    sql = File.read(schema)

    sql.split(';').each do |command|
      ActiveRecord::Base.connection.execute(command)
    end

    ActiveRecord::Base.clear_all_connections!
  end

  desc 'Rebuild the Oracle test database'
  task :rebuild_database => [:drop_database, :build_database]
end
