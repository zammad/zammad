# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module CalendarPreview
  extend ActiveSupport::Concern

  private

  def parse_calendar(file)
    file_content = file.content('preview')
    calendars = Icalendar::Calendar.parse(file_content)
    events = calendars.first&.events || []
    events = events.map { |event| build_event(event) }

    {
      filename: file.filename,
      events:   events,
      type:     file.preferences['Content-Type'] || file.preferences['Mime-Type'] || 'application/octet-stream',
    }
  end

  def build_event(event)
    description = event.description.to_utf8(fallback: :read_as_sanitized_binary)
    summary = event.summary.to_utf8(fallback: :read_as_sanitized_binary)

    {
      title:       summary || description,
      location:    event.location.to_utf8(fallback: :read_as_sanitized_binary),
      start_date:  event.dtstart,
      end_date:    event.dtend,
      attendees:   event.attendee.map { |attendee| attendee.try(:to) },
      organizer:   event.organizer&.try(:to),
      description: description&.strip,
    }
  end
end
