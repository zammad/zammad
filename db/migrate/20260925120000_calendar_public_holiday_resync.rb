# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CalendarPublicHolidayResync < ActiveRecord::Migration[8.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Calendar.find_each do |calendar|
      next if calendar.ical_url.blank?

      resync(calendar)
    end
  end

  private

  def resync(calendar)
    feed = Digest::MD5.hexdigest(calendar.ical_url)
    return if calendar.public_holidays.none? { |_, meta| meta['feed'] == feed }

    events = fetch(calendar)
    return if events.nil?
    return if !move_misplaced_entries(calendar, events, feed)

    add_missing_entries(calendar, events, feed)
    return if calendar.save

    Rails.logger.error "Calendar #{calendar.id}: public holidays left unchanged, calendar is invalid (#{calendar.errors.full_messages.join(', ')})"
  end

  def fetch(calendar)
    Calendar.fetch_parse(calendar.ical_url)
  rescue => e
    Rails.logger.error "Calendar #{calendar.id}: public holidays left unchanged, feed could not be fetched (#{e.message})"
    nil
  end

  def move_misplaced_entries(calendar, events, feed)
    misplaced = calendar.public_holidays.select { |day, meta| meta['feed'] == feed && events[day] != meta['summary'] }

    moves = misplaced.filter_map do |day, meta|
      corrected_day = corrected_day(day, meta['summary'], events)
      [day, corrected_day, meta] if corrected_day
    end

    # Consecutive holidays move onto each other's day, so clear all of them before filling.
    calendar.public_holidays.except!(*moves.map(&:first))
    moves.each { |_, corrected_day, meta| calendar.public_holidays[corrected_day] ||= meta }

    moves.any?
  end

  # Recurring feed events were imported on the UTC day of their occurrence: all-day
  #   events one day early on hosts east of UTC, timed events one day late in zones west of it.
  def corrected_day(day, summary, events)
    return next_day(day) if events[next_day(day)] == summary

    prev_day(day) if events[prev_day(day)] == summary
  end

  def next_day(day)
    Date.parse(day).next_day.iso8601
  end

  def prev_day(day)
    Date.parse(day).prev_day.iso8601
  end

  def add_missing_entries(calendar, events, feed)
    events.each do |day, summary|
      calendar.public_holidays[day] ||= { 'active' => true, 'summary' => summary, 'feed' => feed }
    end
  end
end
