module Biz
  module Timeline
    class Forward < Abstract

      def forward
        self
      end

      private

      def occurred?(period, time)
        period.end_time >= time
      end

      def comparison_period(period, terminus)
        TimeSegment.new(period.start_time, terminus)
      end

      def duration_period(period, duration)
        TimeSegment.new(
          period.start_time,
          period.start_time + duration.in_seconds
        )
      end

    end
  end
end
