module Biz
  class Dates < SimpleDelegator

    def initialize(schedule)
      super(
        Clavius::Schedule.new do |c|
          c.weekdays = schedule.weekdays
          c.excluded = schedule.holidays.map(&:to_date)
        end
      )
    end

  end
end
