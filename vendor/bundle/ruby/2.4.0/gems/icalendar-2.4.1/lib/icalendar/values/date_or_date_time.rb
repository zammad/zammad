module Icalendar
  module Values

    # DateOrDateTime can be used to set an attribute to either a Date or a DateTime value.
    # It should not be used wihtout also invoking the `call` method.
    class DateOrDateTime

      attr_reader :value, :params, :parsed
      def initialize(value, params = {})
        @value = value
        @params = params
      end

      def call
        @parsed ||= begin
                      Icalendar::Values::DateTime.new value, params
                    rescue Icalendar::Values::DateTime::FormatError
                      Icalendar::Values::Date.new value, params
                    end
      end

      def to_ical
        fail NoMethodError, 'You cannot use DateOrDateTime directly. Invoke `call` before `to_ical`'
      end

    end

  end
end
