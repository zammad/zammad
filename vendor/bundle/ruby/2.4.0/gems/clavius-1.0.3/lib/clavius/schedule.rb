module Clavius
  class Schedule

    extend Forwardable

    def initialize(&config)
      @configuration = Configuration.new(&config)
    end

    delegate %i[
      weekdays
      included
      excluded
    ] => :configuration

    def before(date)
      date
        .to_date
        .prev_day
        .downto(Time::BIG_BANG)
        .lazy
        .select(&method(:active?))
    end

    def after(date)
      date
        .to_date
        .next_day
        .upto(Time::HEAT_DEATH)
        .lazy
        .select(&method(:active?))
    end

    def active?(date)
      date = date.to_date

      (weekdays.include?(date.wday) || included.include?(date)) &&
        !excluded.include?(date)
    end

    def days(number)
      Calculation::DaysFrom.new(self, number)
    end

    def between(start_date, end_date)
      start_date
        .to_date
        .upto(end_date.to_date.prev_day)
        .select(&method(:active?))
    end

    protected

    attr_reader :configuration

  end
end
