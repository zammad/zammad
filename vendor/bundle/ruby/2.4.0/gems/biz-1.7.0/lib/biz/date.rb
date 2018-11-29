module Biz
  class Date

    EPOCH = ::Date.new(2006, 1, 1).freeze

    private_constant :EPOCH

    def self.epoch
      EPOCH
    end

    def self.from_day(day)
      EPOCH + day
    end

    def self.for_dst(date, day_time)
      date + (day_time.day_second + Time.hour_seconds) / Time.day_seconds
    end

  end
end
