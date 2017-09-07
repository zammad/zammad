require 'mixin/instance_wrapper'

class Sequencer
  class Units
    class Attributes
      include ::Mixin::InstanceWrapper

      wrap :@attributes

      # Initializes the lifespan store for the attributes
      # of the given Units declarations.
      #
      # @param [Array<Hash{Symbol => Array<:Symbol>}>] declarations the list of Unit declarations.
      #
      # @example
      #  declarations = [{uses: [:attribute1, ...], provides: [:result], ...}]
      #  attributes = Sequencer::Units::Attributes(declarations)
      #
      # @return [nil]
      def initialize(declarations)
        @declarations = declarations

        initialize_attributes
        initialize_lifespan
      end

      # Lists all `provides` declarations of the Units the instance was initialized with.
      #
      # @example
      #  attributes.provided
      #  # => [:result, ...]
      #
      # @return [Array<Symbol>] the list of all `provides` declarations
      def provided
        select do |_attribute, instance|
          instance.will_be_provided?
        end.keys
      end

      # Lists all `uses` declarations of the Units the instance was initialized with.
      #
      # @example
      #  attributes.used
      #  # => [:attribute1, ...]
      #
      # @return [Array<Symbol>] the list of all `uses` declarations
      def used
        select do |_attribute, instance|
          instance.will_be_used?
        end.keys
      end

      # Checks if the given attribute is known in the list of Unit declarations.
      #
      # @example
      #  attributes.known?(:attribute2)
      #  # => false
      #
      # @return [Boolean]
      def known?(attribute)
        key?(attribute)
      end

      private

      def initialize_attributes
        @attributes = Hash.new do |hash, key|
          hash[key] = Sequencer::Units::Attribute.new
        end
      end

      def initialize_lifespan
        @declarations.each_with_index do |unit, index|

          unit[:uses].try(:each) do |attribute|
            self[attribute].to = index
          end

          unit[:provides].try(:each) do |attribute|
            next if self[attribute].will_be_provided?
            self[attribute].from = index
          end
        end
      end
    end
  end
end
