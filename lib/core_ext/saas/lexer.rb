# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Monkey patch for frozen literal string warning

require 'sass'

$VERBOSE = false

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Layout/EmptyLineAfterGuardClause
# rubocop:disable Style/RegexpLiteral
# rubocop:disable Style/NumericPredicate
# rubocop:disable Style/CharacterLiteral
# rubocop:disable Style/StringLiterals
# rubocop:disable Zammad/PreferNegatedIfOverUnless

module Sass
  module Script
    class Lexer
      def special_fun_body(parens, prefix = nil)
        str = prefix || +''
        while (scanned = scan(/.*?([()]|\#\{)/m))
          str << scanned
          if scanned[-1] == ?(
            parens += 1
            next
          elsif scanned[-1] == ?)
            parens -= 1
            next unless parens == 0
          else
            raise "[BUG] Unreachable" unless @scanner[1] == '#{' # '
            str.slice!(-2..-1)
            @interpolation_stack << [:special_fun, parens]
            start_pos = Sass::Source::Position.new(@line, @offset - 2)
            @next_tok = Token.new(:string_interpolation, range(start_pos), @scanner.pos - 2)
          end

          return [:special_fun, Sass::Script::Value::String.new(str)]
        end

        scan(/.*/)
        expected!('")"')
      end
    end
  end
end
