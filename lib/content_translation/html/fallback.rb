# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The translation with simplified formatting, for an answer that cannot be rebuilt into the
# original: the translated text as plain prose, followed by the links, images and protected content
# of the original, which the prose no longer carries.
class ContentTranslation::Html::Fallback
  MARKER     = %r{(?<!\\)\{[[:space:]]*(?:/?[1-9]\d*|[1-9]\d*/)[[:space:]]*\}}
  FORMATTING = %r{\\([[:punct:]])|\*+}

  def initialize(response, fragment)
    @response = response
    @fragment = fragment
  end

  # @return [String, NilClass] nil if there is no text in the answer
  def render
    return if !@response.is_a?(String)

    # Also where the model put the marker on the line of its text.
    paragraphs = @response.split(%r{[[:blank:]]*(?<!\\)\{[[:blank:]]*s[1-9]\d*[[:blank:]]*\}[[:blank:]]*\n?})
      .map { |paragraph| prose(paragraph) }
      .compact_blank
    return if paragraphs.empty?

    (paragraphs.map { |paragraph| "<div>#{paragraph}</div>" } + resources).join
  end

  private

  def prose(paragraph)
    text = plain(paragraph.gsub(MARKER, '')).strip
    return if text.delete('*').blank?

    text.lines(chomp: true).map { |line| ERB::Util.html_escape(line) }.join('<br>')
  end

  # Bold and italic are dropped, asterisks that are not formatting stay. A stray brace leaves the
  # text unreadable for the scanner, so then every asterisk goes.
  def plain(text)
    ContentTranslation::Html::Markdown.tokens(text).filter_map do |type, value|
      next "\n" if type == :break

      value if type == :text
    end.join
  rescue ContentTranslation::Html::InvalidTranslation
    text.gsub(FORMATTING) { Regexp.last_match(1).to_s }
  end

  def resources
    @fragment.css('*').filter_map { |node| resource(node) }.uniq.map { |resource| "<div>#{resource}</div>" }
  end

  def resource(node)
    if node.name == 'a' && node['href']
      href = ERB::Util.html_escape(node['href'])
      "<a href=\"#{href}\">#{href}</a>"
    elsif node.name == 'img' || outermost_protected?(node)
      node.to_html
    end
  end

  def outermost_protected?(node)
    ContentTranslation::Html.protected?(node) &&
      node.ancestors.none? { |ancestor| ancestor.element? && ContentTranslation::Html.protected?(ancestor) }
  end
end
