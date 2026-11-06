# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Removes the text that a person cannot see in Zammad before a model reads it: a model reads text the screen does not
#   show, so a message could carry an instruction the agent never sees. Only what is clearly invisible goes; where the
#   check cannot tell — a colour it does not read, a see-through background, an image, a computed size — the text
#   stays, as a wrong removal takes readable text from summaries and answers. Text that the sanitizer makes visible —
#   hidden by `display: none`, a font size of 0 or a white or black colour on a span or a div — stays, as the agent sees
#   it.
module AI::HiddenText
  module_function

  # Characters that show nothing: format characters such as zero-width spaces and joiners, the bidirectional controls
  #   and the Unicode tag characters, which spell out text no screen shows, and every other character Unicode lets a
  #   screen ignore, such as variation selectors, the combining grapheme joiner and the Hangul fillers.
  IGNORABLE = '\p{Cf}\p{Default_Ignorable_Code_Point}'.freeze

  # One of them stays where it is part of what a screen shows: a joiner between two characters, as words in Persian or
  #   Indic scripts and emoji sequences spell it, and a text or emoji selector after a character. Runs of them go.
  CHARACTERS = %r{
    (?<kept>(?<=[^#{IGNORABLE}\s])(?:[\u200C\u200D](?=[^#{IGNORABLE}\s])|[\uFE0E\uFE0F](?:\u200D(?=[^#{IGNORABLE}\s])|(?![#{IGNORABLE}]))))
    | [#{IGNORABLE}]
  }x

  # Elements whose text a browser does not show: suggestions of a field, and the fallback of media and gauges.
  UNSHOWN_ELEMENTS = %w[datalist canvas video audio meter].freeze

  # Values that leave an element the parent's colour or font size.
  INHERITED = %w[inherit unset revert revert-layer currentcolor].freeze

  # Values that set no background of the element's own.
  NO_BACKGROUND = %w[none inherit initial unset revert revert-layer].freeze

  IMPORTANT = %r{![[:space:]]*important[[:space:]]*\z}

  # A background image or gradient, behind which the contrast of a text cannot be judged.
  IMAGE = %r{url\(|gradient\(}

  # Below this contrast to its background, text is as good as invisible: white on white, or #fefefe on white.
  MIN_CONTRAST = 1.2

  # Smaller text a person does not read.
  MIN_FONT_SIZE_PX = 4

  WHITE = [255, 255, 255].freeze

  # What an element passes on to its children, as the browser inherits it: whether its text is shown at all, the font
  #   size in pixels — nil where the check cannot tell it —, the text's colour — nil where none is set — and the
  #   background below its text; a colour or a background the check cannot tell is :unknown.
  Inherited = Data.define(:unshown, :font_px, :color, :background, :hidden)

  PAGE = Inherited.new(unshown: false, font_px: 16.0, color: nil, background: WHITE, hidden: false)

  # @param text [String, nil]
  # @return [String, nil] the text without the characters that show nothing
  def remove_characters(text)
    return text if !text.is_a?(String)

    text.gsub(CHARACTERS) { Regexp.last_match[:kept].to_s }
  end

  # @param text [String]
  # @return [String] the text as it reads, for comparing it: without every character that shows nothing, also the
  #   joiners and selectors remove_characters keeps
  def readable(text)
    text.gsub(%r{[#{IGNORABLE}]}o, '')
  end

  # @param html [String] the HTML of a stored message
  # @return [String] the HTML without the text a browser does not show or its own styles clearly hide: in an element
  #   whose text is not shown, in a colour without opacity or with almost no contrast to its background, or in a tiny
  #   font size
  def remove_from_html(html)
    # Only these elements and styles hide text once the sanitizer has stored a message; without them, nothing needs parsing.
    return html if !html.to_s.match?(%r{color|font-size|background|#{UNSHOWN_ELEMENTS.join('|')}}i)

    fragment = Nokogiri::HTML::DocumentFragment.parse(html.to_s)
    hidden   = hidden_texts(fragment)
    return html if hidden.empty?

    hidden.each(&:remove)
    fragment.to_html
  end

  # Each element is judged once, from the top down, and passes on what its children inherit.
  def hidden_texts(fragment)
    found = []
    stack = [[fragment, PAGE]]

    until stack.empty?
      node, inherited = stack.pop
      node.children.each do |child|
        if child.element?
          stack << [child, inherited_from(child, inherited)]
        elsif (child.text? || child.cdata?) && inherited.hidden && child.text.strip.present?
          found << child
        end
      end
    end

    found
  end

  def inherited_from(element, parent)
    declarations = style(element)
    color        = color_of(declarations['color'], parent.color)
    background   = background_of(declarations, element['bgcolor'], color, parent.background)
    unshown      = parent.unshown || UNSHOWN_ELEMENTS.include?(element.name)
    font_px      = AI::HiddenText::Size.font_pixels(declarations['font-size'], inherited: parent.font_px)
    tiny         = !font_px.nil? && font_px < MIN_FONT_SIZE_PX

    Inherited.new(unshown:, font_px:, color:, background:, hidden: unshown || tiny || invisible?(color, background))
  end

  # The element's declarations: a later one wins, an important one over all others. The background shorthand counts as
  #   the background colour; an image named in either stays apart, as a later colour leaves it in place.
  def style(element)
    declarations = element['style'].to_s.downcase.split(';').each_with_index.filter_map { |declaration, index| declared(declaration, index) }
    applied      = declarations.sort_by { |_property, _value, important, index| [important, index] }.to_h { |property, value| [property, value] }
    image        = declarations.find { |property, value| property.start_with?('background') && value.match?(IMAGE) }

    image ? applied.merge('background-image' => image.second) : applied
  end

  # @return [Array(String, String, Integer, Integer), nil] the property, its value, its priority and its place
  def declared(declaration, index)
    property, value = declaration.sub(IMPORTANT, '').split(':', 2).map(&:strip)
    return if property.blank? || value.blank?

    [property == 'background' ? 'background-color' : property, value, declaration.match?(IMPORTANT) ? 1 : 0, index]
  end

  # The text's colour: its own, or the parent's where it sets none or takes the parent's; :unknown in a notation the
  #   check does not read.
  def color_of(value, inherited)
    return inherited if value.nil? || INHERITED.include?(value)

    AI::HiddenText::Color.parse(value) || :unknown
  end

  # The background below the element's text: its own colour where it covers what lies below, else the parent's;
  #   :unknown behind an image, a see-through colour or a value the check does not read as one colour, such as a
  #   shorthand that names more than the colour or a value the browser ignores.
  def background_of(declarations, bgcolor, color, below)
    return :unknown if declarations['background-image']

    value = declarations['background-color'] || bgcolor
    return below if value.blank? || NO_BACKGROUND.include?(value)

    rgba = value == 'currentcolor' ? color : AI::HiddenText::Color.parse(value)
    return :unknown if !rgba.is_a?(Array)
    return below if rgba[3].zero?
    return :unknown if rgba[3] < 1

    rgba.first(3)
  end

  # Clearly invisible: a colour without opacity, or one with almost no contrast to its background.
  def invisible?(color, background)
    return false if !color.is_a?(Array)
    return true if color[3] < 0.1
    return false if background == :unknown

    AI::HiddenText::Color.contrast(color.first(3), background) < MIN_CONTRAST
  end
end
