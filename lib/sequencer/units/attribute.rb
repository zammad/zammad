# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Units < SimpleDelegator
    class Attribute

      attr_accessor :from, :to, :optional

      # Checks if the attribute will be provided by one or more Units.
      #
      # @example
      #  attribute.will_be_provided?
      #  # => true
      #
      # @return [Boolean]
      def will_be_provided?
        !from.nil?
      end

      # Checks if the attribute will be used by one or more Units.
      #
      # @example
      #  attribute.will_be_used?
      #  # => true
      #
      # @return [Boolean]
      def will_be_used?
        till.present?
      end

      def optional?
        to.nil? && !optional.nil?
      end

      def cleanup?(index)
        return true if !will_be_used?

        till <= index
      end

      def available?(index)
        index.between?(from, till)
      end

      def till
        [to, optional].compact.max
      end
    end
  end
end
