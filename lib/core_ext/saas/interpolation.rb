# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Monkey patch for frozen literal string warning

require 'sass'

$VERBOSE = false

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Layout/HeredocIndentation
# rubocop:disable Style/StringLiterals
# rubocop:disable Style/HashSyntax
# rubocop:disable Metrics/AbcSize

module Sass::Script::Tree
  class Interpolation < Node
    def _perform(environment)
      res = +""
      res << @before.perform(environment).to_s if @before
      res << " " if @before && @whitespace_before

      val = @mid.perform(environment)
      if @warn_for_color && val.is_a?(Sass::Script::Value::Color) && val.name
        alternative = Operation.new(Sass::Script::Value::String.new("", :string), @mid, :plus)
        Sass::Util.sass_warn <<MESSAGE
WARNING on line #{line}, column #{source_range.start_pos.offset}#{" of #{filename}" if filename}:
You probably don't mean to use the color value `#{val}' in interpolation here.
It may end up represented as #{val.inspect}, which will likely produce invalid CSS.
Always quote color names when using them as strings (for example, "#{val}").
If you really want to use the color value here, use `#{alternative.to_sass}'.
MESSAGE
      end

      res << val.to_s(:quote => :none)
      res << " " if @after && @whitespace_after
      res << @after.perform(environment).to_s if @after
      str = Sass::Script::Value::String.new(
        res, :identifier,
        (to_quoted_equivalent.to_sass if deprecation == :potential)
      )
      str.source_range = source_range
      opts(str)
    end
  end
end
