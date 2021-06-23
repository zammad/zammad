# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    extend ::Sequencer::Mixin::PrefixedConstantize

    PREFIX = 'Sequencer::Sequence::'.freeze

    attr_reader :units, :expecting

    def initialize(units:, expecting: [])
      @units     = units
      @expecting = expecting
    end
  end
end
