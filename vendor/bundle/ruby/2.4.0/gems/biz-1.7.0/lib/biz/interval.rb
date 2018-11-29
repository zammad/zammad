module Biz
  class Interval

    extend Forwardable

    include Comparable

    def self.to_hours(intervals)
      intervals.each_with_object(
        Hash.new do |hours, wday| hours.store(wday, {}) end
      ) do |interval, hours|
        hours[interval.wday_symbol].store(*interval.endpoints.map(&:timestamp))
      end
    end

    def initialize(start_time, end_time, time_zone)
      @start_time = start_time
      @end_time   = end_time
      @time_zone  = time_zone
    end

    attr_reader :start_time,
                :end_time,
                :time_zone

    delegate wday_symbol: :start_time

    def endpoints
      [start_time, end_time]
    end

    def empty?
      start_time >= end_time
    end

    def contains?(time)
      (start_time...end_time).cover?(
        WeekTime.from_time(Time.new(time_zone).local(time))
      )
    end

    def to_time_segment(week)
      TimeSegment.new(
        *endpoints.map { |endpoint|
          Time.new(time_zone).during_week(week, endpoint)
        }
      )
    end

    def &(other)
      lower_bound = [self, other].map(&:start_time).max
      upper_bound = [self, other].map(&:end_time).min

      self.class.new(lower_bound, [lower_bound, upper_bound].max, time_zone)
    end

    def <=>(other)
      return unless other.is_a?(self.class)

      [start_time, end_time, time_zone] <=>
        [other.start_time, other.end_time, other.time_zone]
    end

  end
end
