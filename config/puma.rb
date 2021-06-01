# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

workers Integer(ENV['WEB_CONCURRENCY'] || 0)
threads_count_min = Integer(ENV['MIN_THREADS'] || 5)
threads_count_max = Integer(ENV['MAX_THREADS'] || 30)
threads threads_count_min, threads_count_max

environment ENV.fetch('RAILS_ENV', 'development')

preload_app!

on_worker_boot do
  ActiveRecord::Base.establish_connection
end
