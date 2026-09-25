# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Turns HTML into the compact text an AI model translates, and the model's answer back into HTML.
#
# The model sees text only: every section starts with a {s1} line, line breaks are kept, bold and
# italic are Markdown, and every other element around text is a numbered pair {1}...{/1}. Content
# the model must not touch, like images or code, is a single {1/}. Elements and attributes stay
# here and are restored from the original, so they never pass through the model.
#
# The answer is rebuilt only when all of it is valid. Otherwise it is rendered as plain prose with
# the resources of the original (see Fallback), so the result never mixes original sections into
# the translation.
class ContentTranslation::Html
  class InvalidTranslation < StandardError; end

  class TransformationError < StandardError
    def initialize
      super(__('The response could not be processed.'))
    end
  end

  BLOCK_ELEMENTS = %w[
    address article aside blockquote body caption center dd details dialog div dl dt fieldset figcaption figure
    footer form h1 h2 h3 h4 h5 h6 header hr html li main nav ol p pre section summary table tbody td tfoot th
    thead tr ul
  ].freeze

  PROTECTED_ELEMENTS = %w[code pre kbd samp var script style svg math iframe object].freeze

  SECTION_MARKER = %r{\A[[:blank:]]*\{[[:blank:]]*(s[1-9]\d*)[[:blank:]]*\}[[:blank:]]*\z}

  attr_reader :sections

  def self.protected?(node)
    PROTECTED_ELEMENTS.include?(node.name) || node['translate']&.casecmp?('no')
  end

  def initialize(content)
    guard do
      @fragment = ScrubHtml.new(content.to_s, []).scrub!
      @fragment.xpath('.//comment()').each(&:remove)
      @fragment.css('span').each { |span| merge_following_spans(span) }
      @sections = []
      extract(@fragment)
    end
  end

  def to_s
    sections.map { |section| "{#{section.id}}\n#{section.text}" }.join("\n")
  end

  # Can only be called once, it rebuilds the original document.
  #
  # @param response [String] the model's answer to #to_s
  # @return [String, NilClass] the translated HTML, nil if there is nothing usable in the answer
  def translate(response)
    guard do
      restored = restore(response)

      if !restored
        Rails.logger.info("#{self.class.name}: the answer cannot be rebuilt, it is rendered with simplified formatting.")
        next Fallback.new(response, @fragment).render
      end

      sections.zip(restored).each { |section, nodes| section.replace(nodes) }
      @fragment.to_html
    end
  end

  private

  # Keeps a failure of the transformation apart from a failure of the provider.
  def guard
    yield
  rescue => e
    Rails.logger.error("#{self.class.name}: #{e.class}: #{e.message}")
    raise TransformationError
  end

  def restore(response)
    texts = split(response)
    return if !texts

    restored = sections.zip(texts).map { |section, text| section.restore(text) }
    restored if restored.all?
  end

  # A missing, repeated or reordered section marker makes the assignment of the text to the original
  # sections a guess.
  def split(response)
    return if !response.is_a?(String)

    ids   = []
    texts = []

    response.each_line(chomp: true) do |line|
      if (match = line.match(SECTION_MARKER))
        ids << match[1]
        texts << []
      elsif texts.any?
        texts.last << line
      elsif line.present?
        return nil
      end
    end

    return if ids != sections.map(&:id)

    texts.map { |lines| lines.join("\n").strip }
  end

  # Word splits paragraphs into runs of identical spans. A marker per run would cut the sentences
  # into fragments the model translates one by one.
  def merge_following_spans(span)
    loop do
      space     = span.next_sibling if span.next_sibling&.text? && span.next_sibling.content.match?(%r{\A[[:space:]]*\z})
      following = space ? space.next_sibling : span.next_sibling
      break if following&.name != 'span' || following.attributes.transform_values(&:value) != span.attributes.transform_values(&:value)

      span.add_child(space) if space
      span.add_child(following.children)
      following.unlink
    end
  end

  def extract(parent)
    run = []

    parent.children.each do |node|
      if boundary?(node)
        add_section(run)
        run = []
        extract(node) if !self.class.protected?(node)
      else
        run << node
      end
    end

    add_section(run)
  end

  def boundary?(node)
    return false if !node.element?
    return true if BLOCK_ELEMENTS.include?(node.name)
    return false if self.class.protected?(node)

    node.element_children.any? { |child| boundary?(child) }
  end

  def add_section(nodes)
    nodes = trim(nodes)

    # An element around the whole section leaves the model no boundary to place, so it stays here.
    return add_section(nodes.first.children.to_a) if nodes.one? && wrapper?(nodes.first)

    section = Section.new("s#{sections.size + 1}", nodes)
    sections << section if section.translatable?
  end

  def trim(nodes)
    nodes = nodes.drop_while { |node| insignificant?(node) }
    nodes.reverse.drop_while { |node| insignificant?(node) }.reverse
  end

  def insignificant?(node)
    node.name == 'br' || (node.text? && node.content.match?(%r{\A[[:space:]]*\z}))
  end

  def wrapper?(node)
    node.element? && node.children.any? && !self.class.protected?(node)
  end
end
