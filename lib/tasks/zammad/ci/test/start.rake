# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    namespace :test do

      desc 'Starts all of Zammads services for CI test'
      task :start, [:elasticsearch] do |_task, args| # rubocop:disable Rails/RakeEnvironment
        Rake::Task['zammad:ci:test:prepare'].invoke(args[:elasticsearch])
        Rake::Task['zammad:ci:app:start'].invoke
      end
    end
  end
end
