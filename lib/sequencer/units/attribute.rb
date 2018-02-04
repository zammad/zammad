class Sequencer
  class Units < SimpleDelegator
    class Attribute

      attr_accessor :from, :to

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
        !to.nil?
      end
    end
  end
end
