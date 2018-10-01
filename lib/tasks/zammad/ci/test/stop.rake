namespace :zammad do

  namespace :ci do

    namespace :test do

      desc 'Stop of all Zammad services and cleans up the database(s)'
      task :stop do
        ENV['RAILS_ENV'] ||= 'production'
        ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = 'true'

        # we have to enforce the env
        # otherwise it will fallback to default (develop)
        Rails.env = ENV['RAILS_ENV']

        Rake::Task['zammad:ci:app:stop'].invoke
        Rake::Task['db:drop:all'].invoke

        next if !SearchIndexBackend.enabled?

        Rake::Task['searchindex:drop'].invoke
      end
    end
  end
end
