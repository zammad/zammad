#!/bin/bash
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Restore the database dump of the 'write database dumps' job, which is much faster than
#   running all migrations and seeds again. Falls back to a regular initialization, e.g.
#   if the job did not run or no dump for the current RAILS_ENV is available.

set -e

if .gitlab/database.rb restore; then
  exit 0
fi

echo "Initializing the database from scratch instead."
bundle exec rake zammad:db:init
