module DidYouMean
  module Experimental
    module KeyErrorWithNameAndKeys
      FILE_REGEXP = %r"#{Regexp.quote(__FILE__)}"

      def fetch(name, *)
        super
      rescue KeyError => e
        e.instance_variable_set(:@name, name)
        e.instance_variable_set(:@keys, keys)
        $@.delete_if { |s| FILE_REGEXP =~ s } if $@

        raise e
      end
    end
    Hash.prepend KeyErrorWithNameAndKeys

    class KeyNameChecker
      def initialize(key_error)
        @name = key_error.instance_variable_get(:@name)
        @keys = key_error.instance_variable_get(:@keys)
      end

      def corrections
        @corrections ||= SpellChecker.new(dictionary: @keys).correct(@name).map(&:inspect)
      end
    end

    SPELL_CHECKERS["KeyError"] = KeyNameChecker
    KeyError.prepend DidYouMean::Correctable
  end
end
