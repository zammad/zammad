# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TimeRangeHelper
  def self.relative(from: Time.zone.now, range: 'day', value: 1)
    value = value.to_i

    case range
    when 'day'
      from += value.days
    when 'minute'
      from += value.minutes
    when 'hour'
      from += value.hours
    when 'month'
      from += value.months
    when 'year'
      from += value.years
    end

    from
  end
end
