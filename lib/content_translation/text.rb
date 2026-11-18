# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Plain text content with other texts behind it, as an AI model translates them in one go: every
# one a section behind a {s1} line, like the sections of ContentTranslation::Html. Content without
# such texts needs none of this and is translated as it is.
class ContentTranslation::Text
  MARKER = '\{[[:blank:]]*s[1-9]\d*[[:blank:]]*\}'.freeze

  # At the start of a line only, also where the model put the marker on the line of its text: a
  # marker-like word inside a line is text.
  SECTION_MARKER = %r{^[[:blank:]]*#{MARKER}[[:blank:]]*\n?}

  # A line of the given text that starts like a marker. It is sent with a backslash in front of
  # the brace, which the model is asked to keep, so it is never taken for a marker added here.
  LITERAL_MARKER = %r{^([[:blank:]]*\\*)(#{MARKER})}
  ESCAPED_MARKER = %r{^([[:blank:]]*\\*)\\(#{MARKER})}

  attr_reader :content, :texts, :translated_texts

  # @param texts [Hash{Symbol => String}] the texts behind the content; #translated_texts has
  #   their translations
  def initialize(content, texts:)
    @content          = content.to_s
    @texts            = texts
    @translated_texts = {}
  end

  def to_s
    [content.presence, *texts.values].compact.each_with_index.map { |text, index| "{s#{index + 1}}\n#{escape(text)}" }.join("\n")
  end

  # @param response [String] the model's answer to #to_s
  # @return [String] the translated content, empty if there is none
  def translate(response)
    translation, trailing = split(response.to_s)

    translations      = trailing.split(SECTION_MARKER).map { |text| unescape(text).squish }.compact_blank
    @translated_texts = texts.keys.zip(translations).to_h if translations.size == texts.size

    unescape(translation.sub(%r{\A[[:space:]]*#{marker(1)}}, '')).strip
  end

  private

  # The texts behind the content are told apart from it by their first marker. Without that marker
  # nothing says where the content ends, so all of the answer is content.
  def split(response)
    return ['', response] if content.blank?

    start = response.rindex(%r{^#{marker(2)}})
    return [response, ''] if !start

    [response[0...start], response[start..]]
  end

  def marker(number)
    "[[:blank:]]*\\{[[:blank:]]*s#{number}[[:blank:]]*\\}[[:blank:]]*\\n?"
  end

  def escape(text)
    text.gsub(LITERAL_MARKER) { "#{Regexp.last_match(1)}\\#{Regexp.last_match(2)}" }
  end

  def unescape(text)
    text.gsub(ESCAPED_MARKER) { "#{Regexp.last_match(1)}#{Regexp.last_match(2)}" }
  end
end
