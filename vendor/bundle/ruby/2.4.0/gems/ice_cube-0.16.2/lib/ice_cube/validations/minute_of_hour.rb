module IceCube

  module Validations::MinuteOfHour

    def minute_of_hour(*minutes)
      minutes.flatten.each do |minute|
        unless minute.is_a?(Integer)
          raise ArgumentError, "expecting Integer value for minute, got #{minute.inspect}"
        end
        validations_for(:minute_of_hour) << Validation.new(minute)
      end
      clobber_base_validations(:min)
      self
    end

    class Validation < Validations::FixedValue

      attr_reader :minute
      alias :value :minute

      def initialize(minute)
        @minute = minute
      end

      def type
        :min
      end

      def dst_adjust?
        false
      end

      def build_s(builder)
        builder.piece(:minute_of_hour) << StringBuilder.nice_number(minute)
      end

      def build_hash(builder)
        builder.validations_array(:minute_of_hour) << minute
      end

      def build_ical(builder)
        builder['BYMINUTE'] << minute
      end

      StringBuilder.register_formatter(:minute_of_hour) do |segments|
        str = StringBuilder.sentence(segments)
        IceCube::I18n.t('ice_cube.on_minutes_of_hour', count: segments.size, segments: str)
      end

    end

  end

end
