module Biz
  module Periods
    class Before < Abstract

      def timeline
        super.backward
      end

      private

      def weeks
        Week
          .since_epoch(schedule.in_zone.local(origin))
          .downto(Week.since_epoch(Time.big_bang))
      end

      def relevant?(period)
        origin > period.start_time
      end

      def active_periods(*)
        super.reverse
      end

      def boundary
        @boundary ||= TimeSegment.before(origin)
      end

      def intervals
        @intervals ||= schedule.intervals.reverse
      end

    end
  end
end
