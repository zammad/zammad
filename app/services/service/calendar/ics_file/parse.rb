# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Calendar::IcsFile::Parse < Service::Base
  attr_reader :file

  def initialize(file:)
    @file = file
  end

  def execute
    parse_calendar(file)
  end

  private

  def parse_calendar(file)
    file_content = file.is_a?(::ApplicationController::HasDownload::DownloadFile) ? file.content('preview') : file.content
    file_content = TextEncoding.utf8_encode(file_content, from: file.preferences['Charset'], fallback: :read_as_sanitized_binary)
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
    description = build_text(event.description)

    {
      title:       build_text(event.summary) || description,
      location:    build_text(event.location),
      start_date:  build_date(event.dtstart),
      end_date:    build_date(event.dtend),
      attendees:   event.attendee.filter_map { |attendee| build_participant(attendee) },
      organizer:   build_participant(event.organizer),
      description: description,
    }
  end

  def build_text(value)
    value.to_s.strip.presence
  end

  # An address that is no valid URI, like an empty `mailto:`, is kept as a plain string.
  def build_participant(participant)
    return if participant.nil?

    email = participant.value.to if participant.value.is_a?(URI::MailTo)
    return email if email.present?

    build_text(participant.ical_params['cn']&.first)
  end

  def build_date(date)
    return if date.nil?
    return date if date.is_a?(Icalendar::Values::DateTime)

    date.to_time
  end
end
