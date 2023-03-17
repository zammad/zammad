# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

  # Checks if given time matches timeplan
  # @param [Time]
  # @return [Boolean]
  def contains?(time)
    return false if !valid?

    time_in_zone = ensure_matching_time(time)

    day?(time_in_zone) && hour?(time_in_zone) && minute?(time_in_zone)
  end

  # Calculates next time in timeplan after the given time
  # @param [Time]
  # @return [Time, nil]
  def next_at(time)
    return nil if !valid?

    time_in_zone = ensure_matching_time(time)

    next_run_at_same_day(time_in_zone) || next_run_at_coming_week(time_in_zone)
  end

  # Calculates previous time in timeplan before the given time
  # @param [Time]
  # @return [Time, nil]
  def previous_at(time)
    return nil if !valid?

    time_in_zone = ensure_matching_time(time)

    previous_run_at_same_day(time_in_zone) || previous_run_at_past_week(time_in_zone)
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

  def next_loop_minutes(base_time)
    loop_minutes base_time, range: 0.step(50, 10)
  end

  def previous_loop_minutes(base_time)
    loop_minutes base_time, range: 50.step(0, -10)
  end

  def loop_minutes(base_time, range:)
    return if !hour?(base_time)

    range
      .lazy
      .map  { |minute| base_time.change min: minute }
      .find { |time| minute?(time) }
  end

  def next_loop_hours(base_time)
    loop_hours base_time, range: (base_time.hour..23), minutes_symbol: :next_loop_minutes
  end

  def previous_loop_hours(base_time)
    loop_hours base_time, range: (0..base_time.hour).entries.reverse, minutes_symbol: :previous_loop_minutes
  end

  def loop_hours(base_time, range:, minutes_symbol:)
    return if !day?(base_time)

    range
      .lazy
      .map { |hour| send(minutes_symbol, base_time.change(hour: hour)) }
      .find(&:present?)
  end

  def next_loop_partial_hour(base_time)
    loop_partial_hour base_time, range: base_time.min.step(50, 10)
  end

  def previous_loop_partial_hour(base_time)
    loop_partial_hour base_time, range: base_time.min.step(0, -10)
  end

  def loop_partial_hour(base_time, range:)
    return if !day?(base_time)

    range
      .lazy
      .map  { |minute| base_time.change(min: minute) }
      .find { |time| hour?(time) && minute?(time) }
  end

  def next_run_at_same_day(time)
    day_to_check = time.change min: match_minutes(time.min)

    if day_to_check.min.nonzero?
      date = next_loop_partial_hour(day_to_check)

      return date if date

      day_to_check = day_to_check.change(min: 0)
      day_to_check += 1.hour
    end

    next_loop_hours(day_to_check)
  end

  def next_run_at_coming_week(time)
    (1..7)
      .lazy
      .map { |day| next_loop_hours (time + day.day).beginning_of_day }
      .find(&:present?)
  end

  def previous_run_at_same_day(time)
    day_to_check = time.change min: match_minutes(time.min)

    if day_to_check.min.nonzero?
      date = previous_loop_partial_hour(day_to_check)

      return date if date

      day_to_check = day_to_check.change(min: 0)
      day_to_check -= 1.second
    end

    previous_loop_hours(day_to_check)
  end

  def previous_run_at_past_week(time)
    (1..7)
      .lazy
      .map { |day| previous_loop_hours (time - day.day).end_of_day }
      .find(&:present?)
  end
end
