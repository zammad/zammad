# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence
  extend ::Sequencer::Mixin::PrefixedConstantize

  PREFIX = 'Sequencer::Sequence::'.freeze

  attr_reader :units, :expecting

  def initialize(units:, expecting: [])
    @units     = units
    @expecting = expecting
  end
end
