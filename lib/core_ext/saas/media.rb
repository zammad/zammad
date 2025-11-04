# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Monkey patch for frozen literal string warning

require 'sass'

$VERBOSE = false

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Zammad/PreferNegatedIfOverUnless
# rubocop:disable Layout/SpaceInsideBlockBraces

module Sass::Media
  class Query
    def to_css
      css = +''
      css << resolved_modifier
      css << ' ' unless resolved_modifier.empty?
      css << resolved_type
      css << ' and ' unless resolved_type.empty? || expressions.empty?
      css << expressions.map do |e|
        # It's possible for there to be script nodes in Expressions even when
        # we're converting to CSS in the case where we parsed the document as
        # CSS originally (as in css_test.rb).
        e.map {|c| c.is_a?(Sass::Script::Tree::Node) ? c.to_sass : c.to_s}.join
      end.join(' and ')
      css
    end

    def to_src(options)
      src = +''
      src << Sass::Media._interp_to_src(modifier, options)
      src << ' ' unless modifier.empty?
      src << Sass::Media._interp_to_src(type, options)
      src << ' and ' unless type.empty? || expressions.empty?
      src << expressions.map do |e|
        Sass::Media._interp_to_src(e, options)
      end.join(' and ')
      src
    end
  end
end
