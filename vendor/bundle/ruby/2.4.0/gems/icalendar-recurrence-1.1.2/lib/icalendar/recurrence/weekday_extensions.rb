module Icalendar
  module Recurrence
    module WeekdayExtensions
      attr_accessor :day, :position
    end
  end

  class RRule
    class Weekday
      include Icalendar::Recurrence::WeekdayExtensions
    end
  end
end