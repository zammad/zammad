# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/db/max_connections.rb'

namespace :zammad do
  namespace :db do
    desc 'Calculates recommended max_connections value for PostgreSQL'
    task max_connections: :environment do
      Zammad::DB::MaxConnections.new.calculate
    end
  end
end
