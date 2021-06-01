# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'sequencer/mixin/prefixed_constantize'

class Sequencer
  class Unit
    include ::Mixin::RequiredSubPaths
    extend ::Sequencer::Mixin::PrefixedConstantize

    PREFIX = 'Sequencer::Unit::'.freeze

    # Convenience wrapper for processing a single Unit.
    #
    # ATTENTION: This should only be used for development, testing or debugging purposes.
    # There might be a check in the future to prevent using this method in other scopes.
    #
    # @see #initialize
    # @see #process
    def self.process(unit, parameters, &block)
      new(unit).process(parameters, &block)
    end

    # Initializes a new Sequencer::Unit for processing it.
    #
    # ATTENTION: This should only be used for development, testing or debugging purposes.
    # There might be a check in the future to prevent using this method in other scopes.
    #
    # @param [String] unit the name String for the Unit that should get processed
    def initialize(unit)
      @unit = self.class.constantize(unit)
    end

    # Processes the Sequencer::Unit that the instance was initialized with.
    #
    # ATTENTION: This should only be used for development, testing or debugging purposes.
    # There might be a check in the future to prevent using this method in other scopes.
    #
    # @param [Hash{Symbol => Object}] parameters the parameters for initializing the Sequencer::State
    # @yield [instance] optional block to access the Unit instance
    # @yieldparam instance [Object] the Unit instance for e.g. adding expectations
    def process(parameters)
      @parameters = parameters
      instance    = @unit.new(state)

      # yield instance to apply expectations
      yield instance if block_given?

      state.process do
        instance.process
      end

      state.to_h
    end

    private

    def state
      @state ||= begin
        units = Sequencer::Units.new(
          @unit.name
        )

        sequence = Sequencer::Sequence.new(
          units:     units,
          expecting: @unit.provides,
        )

        Sequencer::State.new(sequence,
                             parameters: @parameters)
      end
    end
  end
end
