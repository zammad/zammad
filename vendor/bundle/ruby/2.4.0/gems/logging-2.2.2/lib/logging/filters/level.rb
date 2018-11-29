require 'set'

module Logging
  module Filters

    # The `Level` filter class provides a simple level-based filtering mechanism
    # that filters messages to only include those from an enumerated list of
    # levels to log.
    class Level < ::Logging::Filter

      # Creates a new level filter that will only allow the given _levels_ to
      # propagate through to the logging destination. The _levels_ should be
      # given in symbolic form.
      #
      # Examples
      #     Logging::Filters::Level.new(:debug, :info)
      #
      def initialize( *levels )
        levels  = levels.map { |level| ::Logging::level_num(level) }
        @levels = Set.new levels
      end

      def allow( event )
        @levels.include?(event.level) ? event : nil
      end

    end
  end
end
