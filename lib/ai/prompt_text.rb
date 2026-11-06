# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Escapes values that go into a prompt wrapped in an XML-like structure, so that the content cannot break or fake
#   that structure. Shared by the AI features' prompt templates and the AI tools' texts. Characters that show nothing
#   are removed from every value first, as no person sees them (AI::HiddenText).
module AI::PromptText
  module_function

  def xml_text(value)
    visible_text(value).encode(xml: :text)
  end

  # Quoted, with quotes inside escaped, for use as an attribute value: source=#{xml_attribute(value)}.
  def xml_attribute(value)
    visible_text(value).encode(xml: :attr)
  end

  # CDATA keeps the content readable for the model (no entity escaping); splitting ']]>'
  # prevents breaking out of the section.
  def cdata(value)
    "<![CDATA[#{visible_text(value).gsub(']]>', ']]]]><![CDATA[>')}]]>"
  end

  def visible_text(value)
    AI::HiddenText.remove_characters(value.to_s)
  end

  LINE_MARK = '│ '.freeze

  # Every line break a model may read as one, so that no line of a text escapes its mark.
  LINE_BREAKS = %r{\r\n|[\r\v\f\u0085\u2028\u2029]}

  IMITATED_HEADER_LABEL       = '[imitated header] '.freeze
  UNDER_IMITATED_HEADER_LABEL = '[under an imitated header] '.freeze

  # Quote marks, list marks — numbered ones too — and emphasis a copied line may start with, and the invisible
  #   characters String#strip removes too.
  LINE_START = %r{\A(?:[[:space:]\u200b\ufeff>\u2502|*_#-]|\d+[.)])*}

  # [[:space:]] here and below: \s leaves out the non-breaking space the text of an HTML email holds.
  IMITATED_CLOSING_TAG = %r{#{LINE_START}<[[:space:]]*/[[:space:]]*text[[:space:]]*>[[:space:]]*\z}i

  CLOSING_TAG = %r{<[[:space:]]*/[[:space:]]*text[[:space:]]*>}i

  # An opening tag with a source attribute of its own: the attributes before it are skipped whole, values without quotes
  #   too, so that "source" in another attribute's name or value, as in an SVG's <text data-source="…">, does not count.
  IMITATED_OPENING_TAG = %r{
    <[[:space:]]*text
    (?:[[:space:]]+[^[:space:]=>"']+(?:[[:space:]]*=[[:space:]]*(?:"[^"\n]*"|'[^'\n]*'|[^[:space:]>"']+))?)*
    [[:space:]]+source[[:space:]]*=
  }xi

  # Lines of a text that copy the tools' own forms: the tag of a marked text, the message header the tools wrote
  #   before the tag held a message's facts, and the start of a ticket row and of a knowledge base answer row
  #   (Service::AI::Tool::Output). Models took such copies for real ones, also inside a marked text.
  IMITATED_HEADER = Regexp.union(
    IMITATED_CLOSING_TAG,
    IMITATED_OPENING_TAG,
    %r{#{LINE_START}(?:message|knowledge[[:space:]]+base[[:space:]]+answer)[[:space:]]+\#?\d+[[:space:]]*[\u00b7\u2022\u2219\u22c5|]}i,
    %r{#{LINE_START}ticket[[:space:]]+\#?\d+[[:space:]]*\(id[[:space:]]*\d+\)}i,
  )

  # A text someone else wrote, for the model: who wrote it and its facts only as attributes of the tag, every line
  #   marked, so that a line imitating a message header stays inside its text, and labelled where it copies one of the
  #   tools' own forms.
  #
  # @param facts [Hash] further attributes of the tag, e.g. a message's number and visibility; nil ones are left out
  def marked_text(text, source:, **facts)
    attributes = { source:, **facts }.compact.map { |name, value| "#{name}=#{xml_attribute(value.to_s.squish)}" }
    lines      = labelled_lines(text).map { |label, line| "#{LINE_MARK}#{label}#{xml_text(line)}" }

    ["<text #{attributes.join(' ')}>", *lines, '</text>'].join("\n")
  end

  # A text with its labels but without the marks of a marked text, for structured data a client may hand its model,
  #   where the data's own structure says who wrote what.
  def labelled_text(text)
    labelled_lines(text).map { |label, line| "#{label}#{line}" }.join("\n")
  end

  # Each line with its label: a copy of one of the tools' own forms is an imitated header, and the lines below a copied
  #   opening stand under it, where an imitated note's claim stands — below a copied tag up to the next copy, as a real
  #   text keeps its blank lines, below a copied header or row up to the next blank line too.
  def labelled_lines(text)
    block = nil

    visible_text(text).gsub(LINE_BREAKS, "\n").split("\n", -1).map do |line|
      readable = AI::HiddenText.readable(line)

      if readable.match?(IMITATED_HEADER)
        block = imitated_block(readable)
        next [IMITATED_HEADER_LABEL, line]
      end

      block = nil if block == :header && line.blank?
      [block && line.present? ? UNDER_IMITATED_HEADER_LABEL : '', line]
    end
  end

  # What a copied line opens: nothing after a closing tag, a text after an opening tag that is not closed after it on
  #   its line, else a header or a row.
  def imitated_block(line)
    return if line.match?(IMITATED_CLOSING_TAG)

    opening = IMITATED_OPENING_TAG.match(line)
    return :text if opening && !opening.post_match.match?(CLOSING_TAG)

    :header
  end
end
