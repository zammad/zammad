# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    class Base

      # Defines the default attributes that will get returned for the sequence.
      # These can be overwritten by giving the :expecting key to a sequence process call.
      #
      # @example
      #  Sequencer::Sequence::Example.expecting
      #  # => [:result, :list]
      #
      # @return [Array<Symbol>] the list of expected result keys.
      def self.expecting
        []
      end

      # Defines the list of Units that form the sequence. The units will get
      # processed in the order they are defined in. The namespaces can be
      # absolute or without the `Sequencer::Unit` prefix.
      #
      # @example
      #  Sequencer::Sequence::Example.sequence
      #  # => ['Import::Example::Resource', 'Sequencer::Unit::Import::Model::Create', ...]
      #
      # @return [Array<String>] the list of units forming the sequence.
      def self.sequence
        raise "Missing implementation of '#{__method__}' method for '#{name}'"
      end

      # This is an internally used method that converts the defined sequence to a
      # Sequencer::Units instance which has special methods.
      #
      # @example
      #  Sequencer::Sequence::Example.units
      #  # => <Sequencer::Units @units=[....>
      #
      # @return [Object]
      def self.units
        Sequencer::Units.new(*sequence)
      end

      # @see .units
      def units
        self.class.units
      end
    end
  end
end
