require 'tzinfo'

module Icalendar
  module Recurrence
    module TimeUtil
      def datetime_to_time(datetime)
        raise ArgumentError, "Unsupported DateTime object passed (must be Icalendar::Values::DateTime#{datetime.class} passed instead)" unless supported_datetime_object?(datetime)
        offset = timezone_offset(datetime.ical_params["tzid"], moment: datetime.to_date)
        offset ||= datetime.strftime("%:z")

        Time.new(datetime.year, datetime.month, datetime.mday, datetime.hour, datetime.min, datetime.sec, offset)
      end

      def date_to_time(date)
        raise ArgumentError, "Must pass a Date object (#{date.class} passed instead)" unless supported_date_object?(date)
        Time.new(date.year, date.month, date.mday)
      end

      def to_time(time_object)
        if supported_time_object?(time_object)
          time_object
        elsif supported_datetime_object?(time_object)
          datetime_to_time(time_object)
        elsif supported_date_object?(time_object)
          date_to_time(time_object)
        elsif time_object.is_a?(String)
          Time.parse(time_object)
        else
          raise ArgumentError, "Unsupported time object passed: #{time_object.inspect}"
        end
      end

      # Calculates offset for given timezone ID (tzid). Optional, specify a
      # moment in time to calulcate this offset. If no moment is specified,
      # use the current time.
      #
      # # If done before daylight savings:
      # TimeUtil.timezone_offset("America/Los_Angeles") => -08:00
      # # Or after:
      # TimeUtil.timezone_offset("America/Los_Angeles", moment: Time.parse("2014-04-01")) => -07:00
      #
      def timezone_offset(tzid, options = {})
        tzid = Array(tzid).first
        options = {moment: Time.now}.merge(options)
        moment = options.fetch(:moment)
        utc_moment = to_time(moment.clone).utc
        tzid = tzid.to_s.gsub(/^(["'])|(["'])$/, "")
        utc_offset =  TZInfo::Timezone.get(tzid).period_for_utc(utc_moment).utc_total_offset # this seems to work, but I feel like there is a lurking bug
        hour_offset = utc_offset/60/60
        hour_offset = "+#{hour_offset}" if hour_offset >= 0
        match = hour_offset.to_s.match(/(\+|-)(\d+)/)
        "#{match[1]}#{match[2].rjust(2, "0")}:00"
      rescue TZInfo::InvalidTimezoneIdentifier => e
        nil
      end

      # See #timezone_offset_at_moment
      def timezone_to_hour_minute_utc_offset(tzid, moment = Time.now)
        timezone_offset(tzid, moment: moment)
      end

      def supported_date_object?(time_object)
        time_object.is_a?(Date) or time_object.is_a?(Icalendar::Values::Date)
      end

      def supported_datetime_object?(time_object)
        time_object.is_a?(Icalendar::Values::DateTime)
      end

      def supported_time_object?(time_object)
        time_object.is_a?(Time)
      end

      # Replaces the existing offset with one associated with given TZID. Does
      # not change hour of day, only the offset. For example, if given a UTC
      # time of 8am, the returned time object will still be 8am but in another
      # timezone. See test for working examples.
      def force_zone(time, tzid)
        offset = timezone_offset(tzid, moment: time)
        raise ArgumentError.new("Unknown TZID: #{tzid}") if offset.nil?
        Time.new(time.year, time.month, time.mday, time.hour, time.min, time.sec, offset)
      end

      extend self
    end

    module TimeExtensions
      def force_zone(tzid)
        TimeUtil.force_zone(self, tzid)
      end
    end
  end
end

class Time
  include Icalendar::Recurrence::TimeExtensions
end
