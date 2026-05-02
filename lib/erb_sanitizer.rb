# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ErbSanitizer

=begin

Whitelist-based ERB sanitizer. Used to make `trusted: true` rendering safe when a
template may contain admin-authored content. Passes through a fixed grammar:

  <% if|elsif @objects[:<object_key>].<name>[.<check>] %>
  <% if|elsif @objects[:<object_key>].<name> ==|!= <literal> %>
  <% else %>
  <% end %>

where `<name>` is one of `allowed_names`, `<check>` is one of RESERVED_CHECKS,
and `<literal>` is a single-quoted string without escapes (`'foo'`), an integer
or float (`5`, `-1.5`), or one of the keywords `true`, `false`, `nil`. The RHS
of a comparison is deliberately restricted to literals — never a variable,
method call, or expression — so no code can run from the template side.

Every other ERB tag has its `<%` escaped to `<%%` and renders as literal text.

  safe = ErbSanitizer.sanitize(
    template_string,
    object_key:    :type_enrichment_data,
    allowed_names: %w[tag_new tagging_guidelines],
  )

=end

  RESERVED_CHECKS = %w[present? blank? empty? any? none? nil?].freeze
  LITERAL_RHS     = %r{'[^'\\]*'|-?\d+(?:\.\d+)?|true|false|nil}

  def self.sanitize(template, object_key:, allowed_names:)
    new(object_key: object_key, allowed_names: allowed_names).sanitize(template)
  end

  def initialize(object_key:, allowed_names:)
    @object_key    = object_key.to_s
    @allowed_names = Array(allowed_names).to_set(&:to_s)
  end

  def sanitize(template)
    depth = 0

    template.gsub(ERB_TAG) do |tag|
      case tag.strip
      when condition_pattern
        next escape_tag(tag) if @allowed_names.exclude?(Regexp.last_match[:name])

        depth += 1 if Regexp.last_match[:keyword] == 'if'
        tag
      when END_TAG
        next escape_tag(tag) if depth.zero?

        depth -= 1
        tag
      when ELSE_TAG
        depth.positive? ? tag : escape_tag(tag)
      else
        escape_tag(tag)
      end
    end
  end

  private

  ERB_TAG  = %r{<%(?!%).*?%>}m
  ELSE_TAG = %r{\A<%-?\s*else\s*-?%>\z}
  END_TAG  = %r{\A<%-?\s*end\s*-?%>\z}
  private_constant :ERB_TAG, :ELSE_TAG, :END_TAG

  def condition_pattern
    @condition_pattern ||= %r{
      \A<%-?\s*
      (?<keyword>if|elsif)\s+
      @objects\[:#{Regexp.escape(@object_key)}\]\.(?<name>\w+)
      (?:
        \.(?<check>#{RESERVED_CHECKS.map { |c| Regexp.escape(c) }.join('|')})
      |
        \s*(?<op>==|!=)\s*(?<rhs>#{LITERAL_RHS.source})
      )?
      \s*-?%>\z
    }x
  end

  def escape_tag(tag)
    tag.sub('<%', '<%%')
  end
end
