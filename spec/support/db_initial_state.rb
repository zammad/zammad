# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require_relative './rake'

# Reset database to be ready for tests
Rake::Task['zammad:db:reset'].execute

# make sure that all migrations of linked packages are executed
Package::Migration.linked
