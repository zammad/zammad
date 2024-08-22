# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Calendar::IcsFile::Parse < Service::BaseWithCurrentUser
  def execute(file:)
    parse_calendar(file)
  end

  private

  def parse_calendar(file)
    file_content = file.is_a?(::ApplicationController::HasDownload::DownloadFile) ? file.content('preview') : file.content
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
      start_date:  build_date(event.dtstart),
      end_date:    build_date(event.dtend),
      attendees:   event.attendee.map { |attendee| attendee.try(:to) },
      organizer:   event.organizer&.try(:to),
      description: description&.strip,
    }
  end

  def build_date(date)
    return date if date.is_a?(Icalendar::Values::DateTime)

    date.to_time
  end
end
