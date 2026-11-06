# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A day, without a time.
class Service::EntityAttribute::Type::CalendarDate < Service::EntityAttribute::Type
  handles 'date'

  def settable?
    true
  end

  def value_schema
    { type: 'string', format: 'date' }
  end

  private

  def convert(value, **)
    ::Date.iso8601(value.to_s).iso8601
  rescue ArgumentError
    invalid(:date, value:)
  end
end
