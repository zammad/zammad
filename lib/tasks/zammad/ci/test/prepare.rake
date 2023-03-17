# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    namespace :test do

      desc 'Prepares Zammad system for CI env'
      task :prepare, [:elasticsearch] do |_task, args| # rubocop:disable Rails/RakeEnvironment
        ENV['RAILS_ENV'] ||= 'production'
        ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = 'true'
        # we have to enforce the env
        # otherwise it will fallback to default (develop)
        Rails.env = ENV['RAILS_ENV']

        Rake::Task['zammad:db:init'].invoke

        Rake::Task['zammad:ci:settings'].invoke(args[:elasticsearch])
      end
    end
  end
end
