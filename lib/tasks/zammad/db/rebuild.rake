# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

namespace :zammad do

  namespace :db do

    desc 'Clears the Cache and reloads the Settings'
    task rebuild: :environment do
      Package::Migration.linked
      ActiveRecord::Base.connection.reconnect!
      ActiveRecord::Base.descendants.each(&:reset_column_information)
      Cache.clear
      Setting.reload
    end
  end
end
