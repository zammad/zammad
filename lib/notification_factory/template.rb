class NotificationFactory::Template

=begin

examples how to use

    cleaned_template = NotificationFactory::Template.new(
      'some template <b><%= d "ticket.title", false %></b> <%= c "fqdn", false %>',
    ).to_s

=end

  def initialize(template)
    @template = template
  end

  def to_s
    strip_html

    @template
  end

  def strip_html
    # some browsers start adding HTML tags
    # fixes https://github.com/zammad/zammad/issues/385
    @template.gsub!(%r{#\{\s*<[^>]+>([^<]+)</[^>]+>\s*\}}, '\1')
    @template.gsub!(/#\{\s*<[^>]+>([^<]+)\s*\}/, '\1')
  end
end
