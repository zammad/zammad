# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Mail
  module Encodings
    class SevenBit
      def self.decode(str)
        ::Mail::Utilities.binary_unsafe_to_lf str
      end

      def self.encode(str)
        ::Mail::Utilities.to_crlf str
      end
    end
  end
end
