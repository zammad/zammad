# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :db do

    desc 'Creates and migrates the DB without seeding'
    task unseeded: %i[db:create db:migrate]
  end
end
