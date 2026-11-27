# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CalendarPublicHolidayCleanup < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Calendar.find_each do |calendar|
      next if calendar.public_holidays.blank? && calendar.ical_url.present?
      # A local file feed can no longer be fetched to restore the removed entries, and fails validation.
      next if calendar.ical_url.present? && !calendar.ical_url.match?(%r{\Ahttps?://}i)

      cache_key = "CalendarIcal::#{calendar.id}"
      Rails.cache.delete(cache_key) if Rails.cache.exist?(cache_key)

      checksum = Digest::MD5.hexdigest(calendar.ical_url.to_s)

      public_holidays_to_keep = calendar.public_holidays.reject { |_, info| info['feed'] == checksum }

      calendar.update!(public_holidays: public_holidays_to_keep)
      calendar.sync_ical
    end
  end
end
