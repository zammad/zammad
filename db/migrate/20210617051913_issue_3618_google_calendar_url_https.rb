# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3618GoogleCalendarUrlHttps < ActiveRecord::Migration[5.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    Calendar
      .where('ical_url LIKE ?', 'http://www.google.com/calendar/ical/%')
      .each do |calendar|
        calendar.ical_url.sub!(%r{^http://}, 'https://')
        calendar.save
      end
  end
end
