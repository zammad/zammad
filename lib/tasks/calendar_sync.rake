# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

namespace :calendar do
  desc 'Sync all calendar iCal feeds'
  task sync: :environment do
    Calendar.find_each do |calendar|
      calendar.sync_ical
    rescue => e
      Rails.logger.error "Calendar ##{calendar.id}: #{e.message}"
    end
  end
end
