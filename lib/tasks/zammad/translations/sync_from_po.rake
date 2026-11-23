# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :translations do

    desc 'Synchronize latest translations from i18n/*.po to the database. Pass "force" to include locales with unchanged files.'
    task :sync, [:force] => :environment do |_task, args|
      puts 'Synchronizing the latest translations from i18n/*.po to the database...'
      Translation.sync(force: args[:force].eql?('force'))
      puts 'done.'
    end
  end
end
