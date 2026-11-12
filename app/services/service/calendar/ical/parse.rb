# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Calendar::Ical::Parse < Service::Base
  attr_reader :body

  def initialize(body:)
    @body = body
  end

  def execute
    cal = Icalendar::Calendar.parse(body).first

    return {} if cal.nil?

    events = {}
    cal.events.each do |event|
      events.merge!(recurrence_days(event))

      next if event.dtstart < 1.year.ago
      next if event.dtstart > 3.years.from_now

      result = day_and_comment_by_event(event, event.dtstart)
      next if !result

      events[result[0]] = result[1]
    end
    events.sort.to_h
  end

  private

  def recurrence_days(event)
    return {} if event.rrule.blank?

    interval_frame_start = 1.year.ago.beginning_of_year.to_date
    interval_frame_end   = 3.years.from_now.end_of_year.to_date

    event
      .occurrences_between(interval_frame_start, interval_frame_end)
      .to_a
      .filter_map { |occurrence| day_and_comment_by_event(event, occurrence_start_time(event, occurrence)) }
      .to_h
  end

  # The recurrence gem starts all-day events at local midnight and returns
  # occurrences in UTC, which lands them on the previous day east of UTC.
  def occurrence_start_time(event, occurrence)
    start_time = occurrence.start_time
    return start_time.getlocal if event.dtstart.is_a?(Icalendar::Values::Date)

    # A TZID known only from a VTIMEZONE block resolves to a fixed offset without a zone.
    zone = event.dtstart.value.try(:time_zone)
    zone ? start_time.in_time_zone(zone) : start_time.getlocal(event.dtstart.value.utc_offset)
  end

  # get day and comment by event
  def day_and_comment_by_event(event, start_time)
    day = "#{start_time.year}-#{format('%<month>02d', month: start_time.month)}-#{format('%<day>02d', day: start_time.day)}"
    comment = event.summary || event.description
    comment = TextEncoding.utf8_encode(comment, fallback: :read_as_sanitized_binary)

    # ignore daylight saving time entries
    return if comment.match?(%r{(daylight saving|sommerzeit|summertime)}i)

    [day, comment]
  end
end
