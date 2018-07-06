require_dependency 'sequencer/mixin/prefixed_constantize'

class Sequencer
  class Sequence
    include ::Mixin::RequiredSubPaths
    extend ::Sequencer::Mixin::PrefixedConstantize

    PREFIX = 'Sequencer::Sequence::'.freeze

    attr_reader :units, :expecting

    def initialize(units:, expecting: [])
      @units     = units
      @expecting = expecting
    end
  end
end
