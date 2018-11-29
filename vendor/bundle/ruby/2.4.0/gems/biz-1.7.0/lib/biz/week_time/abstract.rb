module Biz
  module WeekTime
    class Abstract

      extend Forwardable

      include Comparable

      def self.from_time(time)
        new(
          time.wday * Time.day_minutes +
            time.hour * Time.hour_minutes +
            time.min
        )
      end

      def initialize(week_minute)
        @week_minute = Integer(week_minute)
      end

      def wday_symbol
        day_of_week.symbol
      end

      delegate wday: :day_of_week

      delegate %i[
        hour
        minute
        second
        day_minute
        day_second
        timestamp
      ] => :day_time

      def <=>(other)
        return unless other.is_a?(WeekTime::Abstract)

        week_minute <=> other.week_minute
      end

      protected

      attr_reader :week_minute

    end
  end
end
