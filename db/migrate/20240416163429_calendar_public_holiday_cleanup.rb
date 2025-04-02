# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CalendarPublicHolidayCleanup < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Calendar.find_each do |calendar|
      next if calendar.public_holidays.blank? && calendar.ical_url.present?

      cache_key = "CalendarIcal::#{calendar.id}"
      Rails.cache.delete(cache_key) if Rails.cache.exist?(cache_key)

      checksum = Digest::MD5.hexdigest(calendar.ical_url.to_s)

      public_holidays_to_keep = calendar.public_holidays.reject { |_, info| info['feed'] == checksum }

      calendar.update!(public_holidays: public_holidays_to_keep)
      calendar.sync
    end
  end
end
