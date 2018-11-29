module Biz
  class Configuration

    def initialize
      @raw = Raw.new

      yield raw if block_given?

      Validation.perform(raw)

      raw.freeze
    end

    def intervals
      @intervals ||= begin
        raw
          .hours
          .flat_map { |weekday, hours| weekday_intervals(weekday, hours) }
          .sort
          .freeze
      end
    end

    def breaks
      @breaks ||= begin
        raw
          .breaks
          .flat_map { |date, hours| break_periods(date, hours) }
          .sort
          .freeze
      end
    end

    def holidays
      @holidays ||= begin
        raw
          .holidays
          .to_a
          .uniq
          .map { |date| Holiday.new(date, time_zone) }
          .sort
          .freeze
      end
    end

    def time_zone
      @time_zone ||= TZInfo::TimezoneProxy.new(raw.time_zone)
    end

    def weekdays
      @weekdays ||= raw.hours.keys.uniq.freeze
    end

    def &(other)
      self.class.new do |config|
        config.hours     = Interval.to_hours(intersected_intervals(other))
        config.breaks    = combined_breaks(other)
        config.holidays  = [*raw.holidays, *other.raw.holidays].map(&:to_date)
        config.time_zone = raw.time_zone
      end
    end

    protected

    attr_reader :raw

    private

    def to_proc
      proc do |config|
        config.hours     = raw.hours
        config.breaks    = raw.breaks
        config.holidays  = raw.holidays
        config.time_zone = raw.time_zone
      end
    end

    def time
      @time ||= Time.new(time_zone)
    end

    def weekday_intervals(weekday, hours)
      hours.map { |start_timestamp, end_timestamp|
        Interval.new(
          WeekTime.start(
            DayOfWeek.from_symbol(weekday).start_minute +
              DayTime.from_timestamp(start_timestamp).day_minute
          ),
          WeekTime.end(
            DayOfWeek.from_symbol(weekday).start_minute +
              DayTime.from_timestamp(end_timestamp).day_minute
          ),
          time_zone
        )
      }
    end

    def break_periods(date, hours)
      hours.map { |start_timestamp, end_timestamp|
        TimeSegment.new(
          time.on_date(date, DayTime.from_timestamp(start_timestamp)),
          time.on_date(date, DayTime.from_timestamp(end_timestamp))
        )
      }
    end

    def intersected_intervals(other)
      intervals.flat_map { |interval|
        other
          .intervals
          .map { |other_interval| interval & other_interval }
          .reject(&:empty?)
      }
    end

    def combined_breaks(other)
      Hash.new do |config, date| config.store(date, {}) end.tap do |combined|
        [raw.breaks, other.raw.breaks].each do |configured|
          configured.each do |date, breaks| combined[date].merge!(breaks) end
        end
      end
    end

    Raw = Struct.new(:hours, :breaks, :holidays, :time_zone) do
      module Default
        HOURS = {
          mon: {'09:00' => '17:00'},
          tue: {'09:00' => '17:00'},
          wed: {'09:00' => '17:00'},
          thu: {'09:00' => '17:00'},
          fri: {'09:00' => '17:00'}
        }.freeze

        BREAKS    = [].freeze
        HOLIDAYS  = [].freeze
        TIME_ZONE = 'Etc/UTC'.freeze
      end

      def initialize(*)
        super

        self.hours     ||= Default::HOURS
        self.breaks    ||= Default::BREAKS
        self.holidays  ||= Default::HOLIDAYS
        self.time_zone ||= Default::TIME_ZONE
      end

      alias_method :business_hours=, :hours=
    end

    private_constant :Raw,
                     :Default

  end
end
