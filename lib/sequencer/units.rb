require 'mixin/instance_wrapper'

class Sequencer
  class Units
    include ::Enumerable
    include ::Mixin::InstanceWrapper

    wrap :@units

    # Initializes a new Sequencer::Units instance with the given Units Array.
    #
    # @param [*Array<String>] *units a list of Units with or without the Sequencer::Unit prefix.
    #
    # @example
    #  Sequencer::Units.new('Example::Unit', 'Sequencer::Unit::Second::Unit')
    def initialize(*units)
      @units = units
    end

    # Required #each implementation for ::Enumerable functionality. Constantizes
    # the list of units given when initialized.
    #
    # @example
    #  units.each do |unit|
    #    unit.process(sequencer)
    #  end
    #
    # @return [nil]
    def each
      @units.each do |unit|
        yield constantize(unit)
      end
    end

    # Provides an Array of :uses and :provides declarations for each Unit.
    #
    # @example
    #  units.declarations
    #  #=> [{uses: [:question], provides: [:answer], ...}]
    #
    # @return [Array<Hash{Symbol => Array<Symbol>}>] the declarations of the Units
    def declarations
      collect do |unit|
        {
          uses:     unit.uses,
          provides: unit.provides,
        }
      end
    end

    # Enables the access to an Unit class via index.
    #
    # @param [Integer] index the index for the requested Unit class.
    #
    # @example
    #  units[1]
    #  #=> Sequencer::Unit::Example
    #
    # @return [Object] the Unit class for the requested index
    def [](index)
      constantize(@units[index])
    end

    private

    def constantize(unit)
      Sequencer::Unit.constantize(unit)
    end
  end
end
