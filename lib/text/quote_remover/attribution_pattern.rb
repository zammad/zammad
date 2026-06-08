# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Text
  class QuoteRemover
    class AttributionPattern
      include Mixin::RequiredSubPaths

      # Returns a regex pattern, or nil if using custom match? method
      def self.pattern
        nil
      end

      # Check if a line matches this pattern
      # Override this method for complex matching logic
      def self.match?(line)
        pattern&.match?(line)
      end

      # Whether this pattern should remove ALL content after it
      # Override to return true for forwarded message patterns
      def self.removes_all_after?
        false
      end

      # Find which pattern class matches the line, or nil if none
      def self.find_match(line)
        descendants.find { |klass| klass.match?(line) }
      end
    end
  end
end
