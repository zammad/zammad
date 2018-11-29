module Clavius
  module Calculation
    class DaysFrom

      def initialize(schedule, number)
        @schedule = schedule
        @number   = Integer(number)

        fail ArgumentError, 'negative number' if @number < 0
      end

      def before(origin)
        calculated_day(:before, origin)
      end

      def after(origin)
        calculated_day(:after, origin)
      end

      protected

      attr_reader :schedule,
                  :number

      private

      def calculated_day(direction, origin)
        return zeroeth_day(direction, origin) if number.zero?

        schedule.public_send(direction, origin).take(number).to_a.last
      end

      def zeroeth_day(direction, origin)
        self
          .class
          .new(schedule, 1)
          .public_send(direction, zeroeth_origin(direction, origin))
      end

      def zeroeth_origin(direction, origin)
        case direction
        when :before then origin.next_day
        when :after  then origin.prev_day
        end
      end

    end
  end
end
