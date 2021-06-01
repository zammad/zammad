# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

namespace :zammad do

  namespace :setup do

    desc 'Initializes Zammad via a given auto_wizard JSON file or falls back to contrib/auto_wizard_test.json'
    task :auto_wizard, [:source] => :environment do |_task, args|

      root   = Rails.root
      source = args.fetch(:source, root.join('contrib', 'auto_wizard_test.json'))

      FileUtils.ln(source, root.join('auto_wizard.json'), force: true)

      AutoWizard.setup

      # set system init to done
      Setting.set('system_init_done', true)
    end
  end
end
