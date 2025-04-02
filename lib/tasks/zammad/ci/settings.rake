# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    desc 'Sets all required Settings for performing tests in the CI environment'
    task :settings, [:elasticsearch] => :environment do |_task, args|
      Setting.set('developer_mode', true)
      Setting.set('chat_agent_idle_timeout', '45')

      Setting.set('image_backend', '')
      Setting.set('geo_ip_backend', '')
      Setting.set('geo_location_backend', '')
      Setting.set('geo_calendar_backend', '')

      Scheduler.find_by(method: 'SessionTimeoutJob.perform_now').update!(active: false)

      next if args[:elasticsearch] != 'with_elasticsearch'

      Setting.set('es_url', 'http://elasticsearch:9200')
      Setting.set('es_index', "browser_test_#{ENV['CI_JOB_ID']}")

      Rake::Task['zammad:searchindex:rebuild'].invoke
    end
  end
end
