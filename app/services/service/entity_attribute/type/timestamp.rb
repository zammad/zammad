# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A date and a time, shown and taken in the system's time zone where the caller gives no offset.
class Service::EntityAttribute::Type::Timestamp < Service::EntityAttribute::Type
  handles 'datetime'

  # The form a time is shown in, and taken in besides ISO 8601.
  FORMAT = '%Y-%m-%d %H:%M'.freeze

  class << self
    def format(value)
      value.in_time_zone(time_zone).strftime(FORMAT)
    end

    def time_zone
      Setting.get('timezone_default').presence || 'UTC'
    end
  end

  def label(value)
    self.class.format(value)
  end

  def settable?
    true
  end

  def value_schema
    { type: 'string', format: 'date-time' }
  end

  private

  def convert(value, **)
    zone = ActiveSupport::TimeZone[self.class.time_zone]

    zone.iso8601(value.to_s)
  rescue ArgumentError
    begin
      zone.strptime(value.to_s, FORMAT)
    rescue ArgumentError
      invalid(:date_time, value:)
    end
  end
end
