namespace :zammad do

  namespace :ci do

    namespace :test do

      desc 'Starts all of Zammads services for CI test'
      task :start, [:elasticsearch] do |_task, args|
        ENV['RAILS_ENV'] ||= 'production'
        ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = 'true'
        # we have to enforce the env
        # otherwise it will fallback to default (develop)
        Rails.env = ENV['RAILS_ENV']

        Rake::Task['zammad:flush:cache'].invoke

        Rake::Task['zammad:db:init'].invoke

        Rake::Task['zammad:ci:settings'].invoke(args[:elasticsearch])
        Rake::Task['zammad:ci:app:start'].invoke
      end
    end
  end
end
