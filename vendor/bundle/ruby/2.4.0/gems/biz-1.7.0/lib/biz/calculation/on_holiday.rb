module Biz
  module Calculation
    class OnHoliday

      def initialize(schedule, time)
        @schedule = schedule
        @time     = time
      end

      def result
        schedule.holidays.any? { |holiday| holiday.contains?(time) }
      end

      protected

      attr_reader :schedule,
                  :time

    end
  end
end
