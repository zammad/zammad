module Biz
  module WeekTime
    class << self

      def from_time(time)
        Start.from_time(time)
      end

      def start(week_minute)
        Start.new(week_minute)
      end

      def end(week_minute)
        End.new(week_minute)
      end

      alias build start

    end
  end
end

require 'biz/week_time/abstract'

require 'biz/week_time/end'
require 'biz/week_time/start'
