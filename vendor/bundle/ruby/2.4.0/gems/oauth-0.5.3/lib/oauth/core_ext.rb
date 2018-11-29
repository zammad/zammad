# these are to backport methods from 1.8.7/1.9.1 to 1.8.6

class Object

  unless method_defined?(:tap)
    def tap
      yield self
      self
    end
  end

end

class String

  unless method_defined?(:bytesize)
    def bytesize
      self.size
    end
  end

  unless method_defined?(:bytes)
    def bytes
      require 'enumerator'
      Enumerable::Enumerator.new(self, :each_byte)
    end
  end

end

# TODO: Work around URI.escape obsolete method
#
# 21/May/2016 - We are silencing a warning introduced in 2009
# https://github.com/ruby/ruby/commit/238b979f1789f95262a267d8df6239806f2859cc
#
# The only clear alternative to this problem is to invoke CGI.escape instead
# but that one does not take a secondary argument so we can pass OAuth::RESERVED_CHARACTERS
# As of today, ignoring this secondary argument would introduce 44 errors on our tests
# 181 runs, 511 assertions, 44 failures, 0 errors, 0 skips
#
# If you have a proper way to work around this so we don't need to override ruby core code
# Please send us a Pull Request
module URI
  module Escape
    def escape(*arg)
      DEFAULT_PARSER.escape(*arg)
    end

    def unescape(*arg)
      DEFAULT_PARSER.unescape(*arg)
    end
  end
end
