# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3618GoogleCalendarUrlHttps < ActiveRecord::Migration[5.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    Calendar
      .where('ical_url LIKE ?', 'http://www.google.com/calendar/ical/%')
      .each do |calendar|
        new_url = calendar.ical_url.sub(%r{^http://}, 'https://')
        # skipping validation allows to update old misconfigured calendar
        # https://github.com/zammad/zammad/issues/3641
        calendar.update_attribute :ical_url, new_url # rubocop:disable Rails/SkipsModelValidations
      end
  end
end
