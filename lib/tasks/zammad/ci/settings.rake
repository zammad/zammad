# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    desc 'Sets all required Settings for performing tests in the CI environment'
    task :settings, [:elasticsearch] => :environment do |_task, args|
      Setting.set('developer_mode', true)
      Setting.set('chat_agent_idle_timeout', '45')

      next if args[:elasticsearch] != 'with_elasticsearch'

      Setting.set('es_url', 'http://elasticsearch:9200')
      Setting.set('es_index', "browser_test_#{ENV['CI_BUILD_ID']}")

      Rake::Task['searchindex:rebuild'].invoke
    end
  end
end
