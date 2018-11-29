module Icalendar
  module Recurrence
    module EventExtensions
      def start
        dtstart
      end

      def start_time
        TimeUtil.to_time(start)
      end

      def end
        dtend
      end

      def occurrences_between(begin_time, closing_time)
        schedule.occurrences_between(begin_time, closing_time)
      end

      def schedule
        @schedule ||= Schedule.new(self)
      end

      def tzid
        ugly_tzid = dtstart.ical_params.fetch("tzid", nil)
        return nil if ugly_tzid.nil?

        Array(ugly_tzid).first.to_s.gsub(/^(["'])|(["'])$/, "")
      end
    end
  end

  class Event
    include Icalendar::Recurrence::EventExtensions
  end
end