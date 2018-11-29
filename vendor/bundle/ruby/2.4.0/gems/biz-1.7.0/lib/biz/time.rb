module Biz
  class Time

    MINUTE_SECONDS = 60
    HOUR_MINUTES   = 60
    DAY_HOURS      = 24
    WEEK_DAYS      = 7

    HOUR_SECONDS = HOUR_MINUTES * MINUTE_SECONDS
    DAY_SECONDS  = DAY_HOURS * HOUR_SECONDS

    DAY_MINUTES  = DAY_HOURS * HOUR_MINUTES
    WEEK_MINUTES = WEEK_DAYS * DAY_MINUTES

    BIG_BANG   = ::Time.new(-10**100).freeze
    HEAT_DEATH = ::Time.new(10**100).freeze

    private_constant :MINUTE_SECONDS,
                     :HOUR_MINUTES,
                     :DAY_HOURS,
                     :WEEK_DAYS,
                     :HOUR_SECONDS,
                     :DAY_SECONDS,
                     :DAY_MINUTES,
                     :WEEK_MINUTES,
                     :BIG_BANG,
                     :HEAT_DEATH

    def self.minute_seconds
      MINUTE_SECONDS
    end

    def self.hour_minutes
      HOUR_MINUTES
    end

    def self.day_hours
      DAY_HOURS
    end

    def self.week_days
      WEEK_DAYS
    end

    def self.hour_seconds
      HOUR_SECONDS
    end

    def self.day_seconds
      DAY_SECONDS
    end

    def self.day_minutes
      DAY_MINUTES
    end

    def self.week_minutes
      WEEK_MINUTES
    end

    def self.big_bang
      BIG_BANG
    end

    def self.heat_death
      HEAT_DEATH
    end

    def initialize(time_zone)
      @time_zone = time_zone
    end

    def local(time)
      time_zone.utc_to_local(time.utc)
    end

    def on_date(date, day_time)
      time_zone.local_to_utc(
        ::Time.new(
          date.year,
          date.month,
          date.mday,
          day_time.hour,
          day_time.minute,
          day_time.second
        ),
        true
      )
    rescue TZInfo::PeriodNotFound
      on_date(Date.for_dst(date, day_time), day_time.for_dst)
    end

    def during_week(week, week_time)
      on_date(week.start_date + week_time.wday, week_time.day_time)
    end

    protected

    attr_reader :time_zone

  end
end
