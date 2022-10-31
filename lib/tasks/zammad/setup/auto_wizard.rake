# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :setup do

    desc 'Initializes Zammad via a given auto_wizard JSON file or falls back to contrib/auto_wizard_test.json'
    task :auto_wizard, [:source] => :environment do |_task, args|

      Rails.cache.clear # In case we're coming from `zammad:bootstrap:reset`.

      source = args.fetch(:source, Rails.root.join('contrib/auto_wizard_test.json'))
      FileUtils.ln(source, Rails.root.join('auto_wizard.json'), force: true)

      AutoWizard.setup

      Setting.set('system_init_done', true)
    end
  end
end
