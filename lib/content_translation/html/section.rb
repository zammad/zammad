# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# One run of inline content between block elements: its text for the model, and its translation
# rebuilt from the original nodes.
class ContentTranslation::Html::Section
  # The element restored tokens are added to, and the innermost marker around it.
  Frame = Struct.new(:node, :marker, :own)

  EMPHASIS = { 'strong' => '**', 'b' => '**', 'em' => '*', 'i' => '*' }.freeze
  KINDS    = { 'strong' => :bold, 'b' => :bold, 'em' => :italic, 'i' => :italic }.freeze
  ESCAPED  = %r{[\\*\{\}]}

  # CSS white-space values that display line breaks of the text.
  PRESERVED_LINE_BREAKS = %w[pre pre-wrap pre-line break-spaces].freeze

  # Marker damage seen in model answers: whitespace or byte tokens inside, `{$1}` for `{/1}`, or
  # `/1}` without its opening brace. Escaped characters are matched first so they stay literal.
  DAMAGED_MARKER = %r{\\.|\{[^\{\}\n]{1,32}\}|(?<![\\\{])/([1-9]\d*)\}}

  attr_reader :id, :text

  def initialize(id, nodes)
    @id    = id
    @nodes = nodes

    encode_section(markdown: true)

    # Emphasis inside or next to the same kind can be ambiguous in Markdown. Such a section keeps
    # markers for it instead.
    encode_section(markdown: false) if translatable? && !emphasis_reads_back?
  end

  def translatable?
    @translatable
  end

  # @return [Array<Nokogiri::XML::Node>, NilClass] nil if the translation cannot be rebuilt safely
  def restore(translation)
    repaired = repair(translation)

    build(translation) || build(repaired) || build_without_duplicate_close(repaired)
  end

  def replace(restored)
    [@leading, *restored, @trailing].each do |node|
      next if node == ''

      @nodes.first.add_previous_sibling(node.is_a?(String) ? document.create_text_node(node) : node)
    end
    @nodes.each(&:unlink)
  end

  private

  def encode_section(markdown:)
    @markdown     = markdown
    @markers      = {}
    @translatable = false

    encoded = encode(@nodes, nil)
    @text   = encoded.strip

    # A section can end next to inline content outside of it, e.g. before a block inside a <span>.
    @leading, @trailing = encoded.match(%r{\A([[:space:]]*).*?([[:space:]]*)\z}m).captures
  end

  def emphasis_reads_back?
    restored = build(@text)

    restored.present? && emphasis_of(restored) == emphasis_of(@nodes)
  end

  # Every visible character with the bold and italic it is displayed in.
  def emphasis_of(nodes, kinds = [])
    nodes.flat_map do |node|
      next node.content.gsub(%r{[[:space:]]}, '').chars.map { |character| [character, kinds] } if node.text?

      emphasis_of(node.children, KINDS.key?(node.name) ? (kinds | [KINDS[node.name]]).sort : kinds)
    end
  end

  def encode(nodes, parent)
    nodes.map { |node| encode_node(node, parent) }.join
  end

  def encode_node(node, parent)
    return encode_text(node) if node.text?
    return "\n" if node.name == 'br'
    return encode_emphasis(node, parent) if emphasis?(node)

    encode_marker(node, parent)
  end

  def encode_text(node)
    content = node.content
    @translatable ||= content.match?(%r{[^[:space:]]})

    content = preserved_line_breaks?(node) ? content.gsub(%r{\r\n?}, "\n") : content.gsub(%r{[ \t\r\n\f]+}, ' ')
    content.gsub(ESCAPED) { |character| "\\#{character}" }
  end

  # The line breaks come back as <br>, which displays the same.
  def preserved_line_breaks?(node)
    declared = node.ancestors.lazy.filter_map do |ancestor|
      ancestor['style'].to_s.scan(%r{white-space\s*:\s*([a-z-]+)}i).last&.first if ancestor.element?
    end.first

    PRESERVED_LINE_BREAKS.include?(declared&.downcase)
  end

  def encode_emphasis(node, parent)
    delimiter = EMPHASIS[node.name]
    leading, content, trailing = encode(node.children, parent).match(%r{\A(\s*)(.*?)(\s*)\z}m).captures

    "#{leading}#{delimiter}#{content}#{delimiter}#{trailing}"
  end

  def encode_marker(node, parent)
    number = (@markers.size + 1).to_s
    paired = !ContentTranslation::Html.protected?(node) && node.text.match?(%r{[^[:space:]]})

    @markers[number] = { node:, paired:, parent: }

    return "{#{number}/}" if !paired

    "{#{number}}#{encode(node.children, number)}{/#{number}}"
  end

  # Attributes have to be restored, so such an element keeps a marker.
  def emphasis?(node)
    @markdown && EMPHASIS.key?(node.name) && node.attributes.none? && node.text.present?
  end

  def repair(translation)
    translation.gsub(DAMAGED_MARKER) do |token|
      next token if token.start_with?('\\')
      next "{/#{Regexp.last_match(1)}}" if Regexp.last_match(1)

      match = token.gsub(%r{<0x\h\h>}, ' ').match(%r{\A\{[[:space:]]*([/$])?[[:space:]]*([1-9]\d*)[[:space:]]*(/)?[[:space:]]*\}\z})
      next token if !match || (match[1] && match[3])

      match[1] ? "{/#{match[2]}}" : "{#{match[2]}#{match[3]}}"
    end
  end

  # A span closed twice can be dropped when exactly one of the closings leaves a valid translation.
  # Links and emphasis are never guessed.
  def build_without_duplicate_close(translation)
    closings = @markers.filter_map do |number, marker|
      closing = "{/#{number}}"
      closing if marker[:paired] && marker[:node].name == 'span' && translation.scan(closing).size == 2
    end
    return if closings.size != 1

    closing   = closings.first
    positions = [translation.index(closing), translation.rindex(closing)]

    candidates = positions
      .map { |position| translation.dup.tap { |candidate| candidate[position, closing.length] = '' } }
      .uniq
      .filter_map { |candidate| build(candidate) }

    candidates.first if candidates.one?
  end

  def build(translation)
    root   = document.create_element('div')
    stack  = [Frame.new(root, nil, false)]
    seen   = []
    tokens = ContentTranslation::Html::Markdown.tokens(translation)

    invalid! if tokens.none? { |type, value| type == :text && value.present? }

    tokens.each { |type, value| add_token(type, value, stack, seen) }

    invalid! if stack.size != 1 || seen.size != @markers.size

    root.children.to_a
  rescue ContentTranslation::Html::InvalidTranslation
    nil
  end

  def add_token(type, value, stack, seen)
    top = stack.last

    case type
    when :text
      top.node.add_child(document.create_text_node(value))
    when :break
      top.node.add_child(document.create_element('br'))
    when :open
      stack << Frame.new(top.node.add_child(document.create_element(value)), top.marker, false)
    when :close
      invalid! if stack.size == 1 || top.own || top.node.name != value

      stack.pop
    when :marker_close
      invalid! if !top.own || top.marker != value

      stack.pop
    else
      add_marker(type == :marker_open, value, stack, seen)
    end
  end

  def add_marker(paired, number, stack, seen)
    marker = @markers[number]

    invalid! if !marker || seen.include?(number) || marker[:paired] != paired || marker[:parent] != stack.last.marker

    seen << number
    element = stack.last.node.add_child(marker[:node].dup(1))
    return if !paired

    element.children.remove
    stack << Frame.new(element, number, true)
  end

  def invalid!
    raise ContentTranslation::Html::InvalidTranslation
  end

  def document
    @nodes.first.document
  end
end
