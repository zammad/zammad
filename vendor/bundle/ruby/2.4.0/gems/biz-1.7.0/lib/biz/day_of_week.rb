module Biz
  class DayOfWeek

    SYMBOLS = %i[sun mon tue wed thu fri sat].freeze

    include Comparable

    def self.all
      ALL
    end

    def self.from_symbol(symbol)
      ALL.fetch(SYMBOLS.index(symbol))
    end

    attr_reader :wday

    def initialize(wday)
      @wday = Integer(wday)
    end

    def contains?(week_minute)
      minutes.cover?(week_minute)
    end

    def start_minute
      wday * Time.day_minutes
    end

    def end_minute
      start_minute + Time.day_minutes
    end

    def minutes
      start_minute..end_minute
    end

    def week_minute(day_minute)
      start_minute + day_minute
    end

    def day_minute(week_minute)
      (week_minute - 1) % Time.day_minutes + 1
    end

    def symbol
      SYMBOLS.fetch(wday)
    end

    def wday?(other_wday)
      wday == other_wday
    end

    def <=>(other)
      return unless other.is_a?(self.class)

      wday <=> other.wday
    end

    ALL = (0..6).map(&method(:new)).freeze

    private_constant :SYMBOLS,
                     :ALL

  end
end
