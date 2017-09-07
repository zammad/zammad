class Sequencer
  module Mixin
    module SubSequence
      def sub_sequence(sequence, args = {})
        Sequencer.process(sequence, args)
      end
    end
  end
end
