# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Units < SimpleDelegator

    # Initializes the lifespan store for the attributes
    # of the given Units declarations.
    #
    # @param [Array<Hash{Symbol => Array<:Symbol>}>] declarations the list of Unit declarations.
    #
    # @example
    #  declarations = [{uses: [:attribute1, ...], provides: [:result], ...}]
    #  attributes = Sequencer::Units::Attributes(declarations)
    class Attributes < Delegator

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

      def __getobj__
        @attributes
      end

      def __setobj__(declarations)
        @attributes ||= begin # rubocop:disable Naming/MemoizedInstanceVariableName
          attributes = Hash.new do |hash, key|
            hash[key] = Sequencer::Units::Attribute.new
          end

          attributes.tap do |result|

            declarations.each_with_index do |unit, index|

              unit[:uses].try(:each) do |attribute|
                result[attribute].to = index
              end

              unit[:provides].try(:each) do |attribute|
                next if result[attribute].will_be_provided?

                result[attribute].from = index
              end

              unit[:optional].try(:each) do |attribute|
                result[attribute].optional = index
              end
            end
          end
        end
      end
    end
  end
end
