module Biz
  class DayTime

    VALID_SECONDS = (0..Time.day_seconds).freeze

    module Timestamp
      FORMAT  = '%02d:%02d'.freeze
      PATTERN = /\A(?<hour>\d{2}):(?<minute>\d{2})(:?(?<second>\d{2}))?\Z/
    end

    include Comparable

    class << self

      def from_time(time)
        new(
          time.hour * Time.hour_seconds +
            time.min * Time.minute_seconds +
            time.sec
        )
      end

      def from_minute(minute)
        new(minute * Time.minute_seconds)
      end

      def from_hour(hour)
        new(hour * Time.hour_seconds)
      end

      def from_timestamp(timestamp)
        timestamp.match(Timestamp::PATTERN) { |match|
          new(
            match[:hour].to_i * Time.hour_seconds +
              match[:minute].to_i * Time.minute_seconds +
              match[:second].to_i
          )
        }
      end

      def midnight
        MIDNIGHT
      end

      def endnight
        ENDNIGHT
      end

    end

    def initialize(day_second)
      @day_second = Integer(day_second)

      fail ArgumentError, 'second not within a day' unless valid_second?
    end

    attr_reader :day_second

    def hour
      day_second / Time.hour_seconds
    end

    def minute
      day_second % Time.hour_seconds / Time.minute_seconds
    end

    def second
      day_second % Time.minute_seconds
    end

    def day_minute
      hour * Time.hour_minutes + minute
    end

    def for_dst
      self.class.new((day_second + Time.hour_seconds) % Time.day_seconds)
    end

    def timestamp
      format(Timestamp::FORMAT, hour, minute)
    end

    def <=>(other)
      return unless other.is_a?(self.class)

      day_second <=> other.day_second
    end

    private

    def valid_second?
      VALID_SECONDS.cover?(day_second)
    end

    MIDNIGHT = from_hour(0)
    ENDNIGHT = from_hour(24)

    private_constant :VALID_SECONDS,
                     :Timestamp,
                     :MIDNIGHT,
                     :ENDNIGHT

  end
end
