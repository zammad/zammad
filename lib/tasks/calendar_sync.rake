# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

namespace :calendar do
  desc 'Sync all calendar iCal feeds'
  task sync: :environment do
    Calendar.sync
  end
end
