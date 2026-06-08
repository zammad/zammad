# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Text
  class QuoteRemover
    class Signature
      include Mixin::RequiredSubPaths

      # Check if a line matches this signature pattern
      def self.match?(line)
        raise NotImplementedError
      end
    end
  end
end
