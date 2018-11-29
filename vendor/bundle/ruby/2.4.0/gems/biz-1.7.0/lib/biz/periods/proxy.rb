module Biz
  module Periods
    class Proxy

      def initialize(schedule)
        @schedule = schedule
      end

      def after(origin)
        After.new(schedule, origin)
      end

      def before(origin)
        Before.new(schedule, origin)
      end

      def on(date)
        schedule
          .periods
          .after(schedule.in_zone.on_date(date, DayTime.midnight))
          .timeline
          .until(schedule.in_zone.on_date(date, DayTime.endnight))
      end

      protected

      attr_reader :schedule

    end
  end
end
