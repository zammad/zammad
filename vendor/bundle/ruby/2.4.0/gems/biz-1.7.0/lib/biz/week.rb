module Biz
  class Week

    include Comparable

    def self.from_date(date)
      new((date - Date.epoch).to_i / Time.week_days)
    end

    def self.from_time(time)
      from_date(time.to_date)
    end

    class << self

      alias since_epoch from_time

    end

    def initialize(week)
      @week = Integer(week)
    end

    def start_date
      Date.from_day(week * Time.week_days)
    end

    def succ
      self.class.new(week.succ)
    end

    def downto(final_week)
      return enum_for(:downto, final_week) unless block_given?

      week.downto(final_week.week).each do |raw_week|
        yield self.class.new(raw_week)
      end
    end

    def +(other)
      self.class.new(week + other.week)
    end

    def <=>(other)
      return unless other.is_a?(self.class)

      week <=> other.week
    end

    protected

    attr_reader :week

  end
end
