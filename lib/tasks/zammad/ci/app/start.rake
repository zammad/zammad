namespace :zammad do

  namespace :ci do

    namespace :app do

      desc 'Starts the application and uses BROWSER_PORT, RAILS_ENV and WS_PORT ENVs'
      task :start do
        Rake::Task['zammad:ci:service:puma:start'].invoke(ENV['BROWSER_PORT'], ENV['RAILS_ENV'])
        Rake::Task['zammad:ci:service:websocket:start'].invoke(ENV['WS_PORT'])
        Rake::Task['zammad:ci:service:scheduler:start'].invoke
      end
    end
  end
end
