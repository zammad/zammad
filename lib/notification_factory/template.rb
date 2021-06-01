# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class NotificationFactory::Template

=begin

examples how to use

    cleaned_template = NotificationFactory::Template.new(
      'some template <b>#{ticket.title}</b> #{config.fqdn}',
      true,
    ).to_s

=end

  def initialize(template, escape)
    @template = template
    @escape = escape
  end

  def to_s
    @template.gsub(%r{\#{\s*(.*?)\s*}}m) do
      # some browsers start adding HTML tags
      # fixes https://github.com/zammad/zammad/issues/385
      input_template = $1.gsub(%r{\A<.+?>\s*|\s*<.+?>\z}, '')

      case input_template
      when %r{\At\('(.+?)'\)\z}m
        %(<%= t "#{sanitize_text($1)}", #{@escape} %>)
      when %r{\At\((.+?)\)\z}m
        %(<%= t d"#{sanitize_object_name($1)}", #{@escape} %>)
      when %r{\Aconfig\.(.+?)\z}m
        %(<%= c "#{sanitize_object_name($1)}", #{@escape} %>)
      else
        %(<%= d "#{sanitize_object_name(input_template)}", #{@escape} %>)
      end
    end
  end

  def sanitize_text(string)
    string&.tr("\t\r\n", '')
          &.gsub(%r{(?<!\\)(?=")}, '\\')
  end

  def sanitize_object_name(string)
    string&.tr("\t\r\n\f \"'§;", '')
  end

end
