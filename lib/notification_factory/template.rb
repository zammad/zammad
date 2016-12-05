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
    strip_html

    @template
  end

  def strip_html
    # some browsers start adding HTML tags
    # fixes https://github.com/zammad/zammad/issues/385
    @template.gsub!(/\#\{\s*t\((.+?)\)\s*\}/m) do
      content = $1
      if content =~ /^'(.+?)'$/
        "<%= t \"#{strip_content($1)}\", #{@escape} %>"
      else
        "<%= t d\"#{strip_variable(content)}\", #{@escape} %>"
      end
    end
    @template.gsub!(/\#\{\s*config\.(.+?)\s*\}/m) do
      "<%= c \"#{strip_variable($1)}\", #{@escape} %>"
    end
    @template.gsub!(/\#\{(.*?)\}/m) do
      "<%= d \"#{strip_variable($1)}\", #{@escape} %>"
    end
  end

  def strip_content(string)
    return string if !string
    string.gsub!(/\t|\r|\n/, '')
    string.gsub!(/"/, '\"')
    string
  end

  def strip_variable(string)
    return string if !string
    string.gsub!(/\t|\r|\n|"|'|§|;/, '')
    string.gsub!(/\s*/, '')
    string.gsub!(/<.+?>/, '')
    string
  end

end
