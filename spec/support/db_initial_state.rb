# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_relative './rake'

# Reset database to be ready for tests
Rake::Task['zammad:db:reset'].execute

# make sure that all migrations of linked packages are executed
Package::Migration.linked
