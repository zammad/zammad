module Biz
  class Duration

    include Comparable

    class << self

      def seconds(seconds)
        new(seconds)
      end

      alias second seconds

      def minutes(minutes)
        new(minutes * Time.minute_seconds)
      end

      alias minute minutes

      def hours(hours)
        new(hours * Time.hour_seconds)
      end

      alias hour hours

    end

    def initialize(seconds)
      @seconds = Integer(seconds)
    end

    def in_seconds
      seconds
    end

    def in_minutes
      seconds / Time.minute_seconds
    end

    def in_hours
      seconds / Time.hour_seconds
    end

    def +(other)
      self.class.new(seconds + other.seconds)
    end

    def -(other)
      self.class.new(seconds - other.seconds)
    end

    def positive?
      seconds > 0
    end

    def abs
      self.class.new(seconds.abs)
    end

    def <=>(other)
      return unless other.is_a?(self.class)

      seconds <=> other.seconds
    end

    protected

    attr_reader :seconds

  end
end
