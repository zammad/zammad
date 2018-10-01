namespace :zammad do

  namespace :ci do

    desc 'Sets all required Settings for performing tests in the CI environment'
    task :settings, [:elasticsearch] => :environment do |_task, args|
      Setting.set('developer_mode', true)
      Setting.set('websocket_port', ENV['WS_PORT'])
      Setting.set('fqdn', "#{ENV['IP']}:#{ENV['BROWSER_PORT']}")
      Setting.set('chat_agent_idle_timeout', '45')

      next if args[:elasticsearch] != 'with_elasticsearch'

      Setting.set('es_url', 'http://localhost:9200')
      Setting.set('es_index', "browser_test_#{ENV['CI_BUILD_ID']}")

      Rake::Task['searchindex:rebuild'].invoke
    end
  end
end
