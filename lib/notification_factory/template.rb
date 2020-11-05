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
    @template.gsub(/\#{\s*(.*?)\s*}/m) do
      # some browsers start adding HTML tags
      # fixes https://github.com/zammad/zammad/issues/385
      input_template = $1.gsub(/\A<.+?>\s*|\s*<.+?>\z/, '')

      case input_template
      when /\At\('(.+?)'\)\z/m
        %(<%= t "#{sanitize_text($1)}", #{@escape} %>)
      when /\At\((.+?)\)\z/m
        %(<%= t d"#{sanitize_object_name($1)}", #{@escape} %>)
      when /\Aconfig\.(.+?)\z/m
        %(<%= c "#{sanitize_object_name($1)}", #{@escape} %>)
      else
        %(<%= d "#{sanitize_object_name(input_template)}", #{@escape} %>)
      end
    end
  end

  def sanitize_text(string)
    string&.tr("\t\r\n", '')
          &.gsub(/(?<!\\)(?=")/, '\\')
  end

  def sanitize_object_name(string)
    string&.tr("\t\r\n\f \"'§;", '')
  end

end
