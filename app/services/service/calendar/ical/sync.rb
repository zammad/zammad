# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Calendar::Ical::Sync < Service::Base
  attr_reader :calendar

  def initialize(calendar:, save: true)
    @calendar = calendar
    @save     = save
  end

  def execute
    return false if already_synced?

    synced = sync_feed

    return false if save? && !persist

    update_cache if synced

    true
  end

  private

  def save? = @save

  def sync_feed
    events = fetch_events
    remove_stale_entries
    merge_events(events)
    calendar.last_log = nil
    true
  rescue => e
    calendar.last_log = e.inspect
    false
  ensure
    calendar.last_sync = Time.zone.now
  end

  def persist
    return true if calendar.save

    Rails.logger.error "Calendar ##{calendar.id}: #{calendar.errors.full_messages.join(', ')}"
    false
  end

  def already_synced?
    return false if !calendar.id
    return false if calendar.last_log

    cache = read_cache
    cache.present? && cache[:ical_url] == calendar.ical_url
  end

  def fetch_events
    return {} if calendar.ical_url.blank?

    Service::Calendar::Ical::Parse.execute(
      body: Service::Calendar::Ical::Fetch.execute(url: calendar.ical_url),
    )
  end

  def remove_stale_entries
    calendar.public_holidays.delete_if do |_day, meta|
      meta['feed'] && meta['feed'] != feed_checksum
    end
  end

  def merge_events(events)
    events.each do |day, summary|
      calendar.public_holidays[day] ||= {}

      next if calendar.public_holidays[day].key?('active')
      next if summary == calendar.public_holidays[day]['summary']

      calendar.public_holidays[day] = {
        'active'  => true,
        'summary' => summary,
        'feed'    => feed_checksum,
      }
    end
  end

  # an unsaved sync is not durable, so the next run has to fetch the feed again
  def update_cache
    return if !calendar.id

    save? ? write_cache : delete_cache
  rescue => e
    log_cache_error(e)
  end

  def read_cache
    Rails.cache.read(cache_key)
  rescue => e
    log_cache_error(e)
    nil
  end

  def write_cache
    Rails.cache.write(
      cache_key,
      { ical_url: calendar.ical_url },
      { expires_in: 1.day },
    )
  end

  def delete_cache
    Rails.cache.delete(cache_key)
  end

  # an unreachable cache only costs a repeated fetch, so it must not fail the sync
  def log_cache_error(e)
    Rails.logger.error "Calendar ##{calendar.id}: iCal sync cache unavailable: #{e.inspect}"
  end

  # a blank URL hashes to a checksum no feed entry carries, which drops them all
  def feed_checksum
    @feed_checksum ||= Digest::MD5.hexdigest(calendar.ical_url.to_s)
  end

  def cache_key
    "CalendarIcal::#{calendar.id}"
  end
end
