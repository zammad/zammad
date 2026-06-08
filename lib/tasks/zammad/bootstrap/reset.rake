# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :bootstrap do

    # db:schema:dump added to deal with Rails 8 migration changes.
    # In Rails 8 initial migration loads schema.rb instea.d of executing all migrations
    # This causes issues when switching between branches.
    # Dumping schema ensures that all migrations are run and schema.rb is up to date.
    desc 'Resets a Zammad instance and reinitializes it'
    task reset: %i[
      zammad:db:truncate
      db:schema:dump
      db:migrate
      db:seed
      zammad:setup:auto_wizard
    ]
  end
end
