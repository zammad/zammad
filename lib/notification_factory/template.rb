# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class NotificationFactory::Template

=begin

examples how to use

    cleaned_template = NotificationFactory::Template.new(
      'some template <b>#{ticket.title}</b> #{config.fqdn}',
      true,
      false,  # Allow ERB tags in the template?
    ).to_s

=end

  def initialize(template, escape, trusted)
    @template = template
    @escape   = escape
    @trusted  = trusted
  end

  def to_s
    result = @template
    result = result.gsub(%r{<%(?!%)}, '<%%') if !@trusted
    result = result.gsub(%r{(?<!\\)\#{\s*(.*?)\s*}}m) do
      # some browsers start adding HTML tags
      # fixes https://github.com/zammad/zammad/issues/385
      input_template = $1.gsub(%r{\A<.+?>\s*|\s*<.+?>\z}, '')

      case input_template
      when %r{\At\('(.+?)'\)\z}m
        %(<%= t "#{sanitize_text($1)}", #{@escape} %>)
      when %r{\At\((.+?)\)\z}m
        %(<%= t d"#{sanitize_object_name($1)}", #{@escape} %>)
      when %r{\Adt\((.+?)\)\z}m
        %(<%= dt "#{sanitize_text($1)}" %>)
      when %r{\Aconfig\.(.+?)\z}m
        %(<%= c "#{sanitize_object_name($1)}", #{@escape} %>)
      else
        %(<%= d "#{sanitize_object_name(input_template)}", #{@escape} %>)
      end
    end
    result.gsub(%r{\\\#{\s*(.*?)\s*}}m, '#{\1}')
  end

  def sanitize_text(string)
    # Escape backslashes and double quotes so the value cannot break out of the
    # generated `"…"` Ruby string literal. Backslashes must be escaped first,
    # otherwise an already-escaped backslash (`\\"`) would smuggle a real closing
    # quote past the escaping and turn the rest of the template into executable Ruby.
    string&.tr("\t\r\n", '')
          &.gsub(%r{[\\"]}) { |char| "\\#{char}" }
  end

  def sanitize_object_name(string)
    # `tr` applies its own backslash escaping on top of Ruby's, so the four
    # backslashes in the source are needed to add a single literal `\` to the set.
    string&.tr("\t\r\n\f \\\\\"'§;", '')
  end

end
