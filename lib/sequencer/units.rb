# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'sequencer/units/attribute'
require_dependency 'sequencer/units/attributes'

class Sequencer
  class Units < SimpleDelegator
    include ::Enumerable

    # Initializes a new Sequencer::Units instance with the given Units Array.
    #
    # @param [*Array<String>] *units a list of Units with or without the Sequencer::Unit prefix.
    #
    # @example
    #  Sequencer::Units.new('Example::Unit', 'Sequencer::Unit::Second::Unit')
    def initialize(*units)
      super(units)
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
      __getobj__.each do |unit|
        yield constantize(unit)
      end
    end

    # Provides an Array of :uses, :provides and :optional declarations for each Unit.
    #
    # @example
    #  units.declarations
    #  #=> [{uses: [:question], provides: [:answer], optional: [:facts], ...}]
    #
    # @return [Array<Hash{Symbol => Array<Symbol>}>] the declarations of the Units
    def declarations
      collect do |unit|
        {
          uses:     unit.uses,
          provides: unit.provides,
          optional: unit.optional,
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
      constantize(__getobj__[index])
    end

    private

    def constantize(unit)
      Sequencer::Unit.constantize(unit)
    end
  end
end
