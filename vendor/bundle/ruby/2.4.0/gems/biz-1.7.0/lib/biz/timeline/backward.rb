module Biz
  module Timeline
    class Backward < Abstract

      def backward
        self
      end

      private

      def occurred?(period, time)
        period.start_time <= time
      end

      def comparison_period(period, terminus)
        TimeSegment.new(terminus, period.end_time)
      end

      def duration_period(period, duration)
        TimeSegment.new(
          period.end_time - duration.in_seconds,
          period.end_time
        )
      end

    end
  end
end
