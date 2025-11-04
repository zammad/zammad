# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Monkey patch for frozen literal string warning

require 'sass'

$VERBOSE = false

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Style/StringLiterals
# rubocop:disable Style/HashSyntax

module Sass::Script::Tree
  class StringInterpolation < Node
    def to_sass(opts = {})
      quote = type == :string ? opts[:quote] || quote_for(self) || '"' : :none
      opts = opts.merge(:quote => quote)

      res = +""
      res << quote if quote != :none
      res << _to_sass(before, opts)
      res << '#{' << @mid.to_sass(opts.merge(:quote => nil)) << '}'
      res << _to_sass(after, opts)
      res << quote if quote != :none
      res
    end

    def _perform(environment)
      res = +""
      before = @before.perform(environment)
      res << before.value
      mid = @mid.perform(environment)
      res << (mid.is_a?(Sass::Script::Value::String) ? mid.value : mid.to_s(:quote => :none))
      res << @after.perform(environment).value
      opts(Sass::Script::Value::String.new(res, before.type))
    end
  end
end
