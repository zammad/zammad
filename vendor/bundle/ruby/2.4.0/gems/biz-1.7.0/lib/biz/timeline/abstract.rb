module Biz
  module Timeline
    class Abstract

      def initialize(periods)
        @periods = periods.lazy
      end

      def until(terminus)
        return enum_for(:until, terminus) unless block_given?

        periods
          .map { |period| period & comparison_period(period, terminus) }
          .each do |period|
            yield period unless period.empty?

            break if occurred?(period, terminus)
          end
      end

      def for(duration)
        return enum_for(:for, duration) unless block_given?

        remaining = duration

        periods
          .map { |period| period & duration_period(period, remaining) }
          .each do |period|
            yield period unless period.empty?

            remaining -= period.duration

            break unless remaining.positive?
          end
      end

      protected

      attr_reader :periods

    end
  end
end
