# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/db/pgloader.rb'
Tasks::Zammad::DB::Pgloader.register_rake_task
