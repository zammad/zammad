module Clavius
  class Configuration

    def initialize
      @raw = Raw.new.tap do |raw| yield raw if block_given? end
    end

    def weekdays
      @weekdays ||= begin
        raw
          .weekdays
          .select { |weekday| Time::WEEKDAYS.include?(weekday) }
          .map    { |weekday| Time::WEEKDAYS.index(weekday) }
          .to_set
          .freeze
      end
    end

    def included
      @included ||= exception_configuration(raw.included)
    end

    def excluded
      @excluded ||= exception_configuration(raw.excluded)
    end

    protected

    attr_reader :raw

    private

    def exception_configuration(dates)
      dates
        .select { |date| date.respond_to?(:to_date) }
        .map(&:to_date)
        .to_set
        .freeze
    end

    Raw = Struct.new(:weekdays, :included, :excluded) do
      module Default
        WEEKDAYS = Set.new(%i[mon tue wed thu fri]).freeze
        INCLUDED = Set.new.freeze
        EXCLUDED = Set.new.freeze
      end

      def initialize(*)
        super

        self.weekdays ||= Default::WEEKDAYS
        self.included ||= Default::INCLUDED
        self.excluded ||= Default::EXCLUDED
      end
    end

  end
end
