# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Monkey patch for frozen literal string warning

require 'sass'

$VERBOSE = false

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Style/StringLiterals
# rubocop:disable Lint/UnusedMethodArgument

module Sass
  module Selector
    class Attribute < Simple
      def to_s(opts = {})
        res = +"["
        res << @namespace << "|" if @namespace
        res << @name
        res << @operator << @value if @value
        res << " " << @flags if @flags
        res << "]"
      end
    end
  end
end
