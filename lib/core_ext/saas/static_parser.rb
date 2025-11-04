# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Monkey patch for frozen literal string warning

require 'sass'

$VERBOSE = false

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Layout/EmptyLineAfterGuardClause
# rubocop:disable Zammad/PreferNegatedIfOverUnless
# rubocop:disable Style/RegexpLiteral
# rubocop:disable Layout/SpaceInsideBlockBraces
# rubocop:disable Performance/CollectionLiteralInLoop

module Sass
  module SCSS
    class StaticParser < Parser
      def selector_comma_sequence
        sel = selector
        return unless sel
        selectors = [sel]
        ws = +''
        while tok(/,/)
          ws << str {ss}
          next unless (sel = selector)
          selectors << sel
          if ws.include?("\n")
            selectors[-1] = Selector::Sequence.new(["\n"] + selectors.last.members)
          end
          ws = +''
        end
        Selector::CommaSequence.new(selectors)
      end
    end
  end
end
