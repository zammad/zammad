# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  module Mixin
    # Classes that extend this module need a PREFIX constant.
    module PrefixedConstantize
      # Returns the class for a given name String independend of the prefix.
      #
      # @param [String] sequence the name String for the requested class
      #
      # @example
      #  Sequencer::Sequence.constantize('ExampleSequence')
      #  #=> Sequencer::Sequence::ExampleSequence
      #
      # @example
      #  Sequencer::Unit.constantize('Sequencer::Unit::Example::Unit')
      #  #=> Sequencer::Unit::Example::Unit
      #
      # @return [Object] the class for the given String
      def constantize(name_string)
        namespace(name_string).constantize
      end

      # Returns the complete class namespace for a given name String
      # independend of the prefix.
      #
      # @param [String] sequence the name String for the requested class namespace
      #
      # @example
      #  Sequencer::Sequence.namespace('ExampleSequence')
      #  #=> 'Sequencer::Sequence::ExampleSequence'
      #
      # @example
      #  Sequencer::Unit.namespace('Sequencer::Unit::Example::Unit')
      #  #=> 'Sequencer::Unit::Example::Unit'
      #
      # @return [String] the class namespace for the given String
      def namespace(name_string)
        prefix = const_get(:PREFIX)
        return name_string if name_string.start_with?(prefix)

        "#{prefix}#{name_string}"
      end
    end
  end
end
