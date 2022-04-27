# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class TimeplanCalculation
  DAY_MAP = {
    0 => 'Sun',
    1 => 'Mon',
    2 => 'Tue',
    3 => 'Wed',
    4 => 'Thu',
    5 => 'Fri',
    6 => 'Sat'
  }.freeze

  attr_reader :timeplan

  def initialize(timeplan, timezone)
    @timeplan = timeplan.deep_transform_keys(&:to_s)
    @timezone = timezone
  end

  def contains?(time)
    return false if !valid?

    time_in_zone = ensure_matching_time(time)

    day?(time_in_zone) && hour?(time_in_zone) && minute?(time_in_zone)
  end

  def next_at(time)
    return nil if !valid?

    time_in_zone = ensure_matching_time(time)

    next_run_at_same_day(time_in_zone) || next_run_at_coming_week(time_in_zone)
  end

  private

  def ensure_matching_time(time)
    time.in_time_zone @timezone
  end

  def valid?
    timeplan.key?('days') && timeplan.key?('hours') && timeplan.key?('minutes')
  end

  def match_minutes(minutes)
    minutes / 10 * 10
  end

  def day?(time)
    timeplan['days'][DAY_MAP[time.wday]]
  end

  def hour?(time)
    timeplan.dig 'hours', time.hour.to_s
  end

  def minute?(time)
    timeplan.dig 'minutes', match_minutes(time.min).to_s
  end

  def loop_minutes(base_time)
    return if !hour?(base_time)

    0
      .step(50, 10)
      .lazy
      .map  { |minute| base_time.change min: minute }
      .find { |time| minute?(time) }
  end

  def loop_hours(base_time)
    return if !day?(base_time)

    (base_time.hour..23)
      .lazy
      .map { |hour| loop_minutes base_time.change hour: hour }
      .find(&:present?)
  end

  def loop_partial_hour(base_time)
    return if !day?(base_time)

    base_time
      .min
      .step(50, 10)
      .lazy
      .map  { |minute| base_time.change(min: minute) }
      .find { |time| hour?(time) && minute?(time) }
  end

  def next_run_at_same_day(time)
    day_to_check = time.change min: match_minutes(time.min)

    if day_to_check.min.nonzero?
      date = loop_partial_hour(day_to_check)

      return date if date

      day_to_check = day_to_check.change(min: 0)
      day_to_check += 1.hour
    end

    loop_hours(day_to_check)
  end

  def next_run_at_coming_week(time)
    (1..7)
      .lazy
      .map { |day| loop_hours (time + day.day).midnight }
      .find(&:present?)
  end
end
