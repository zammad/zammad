# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Builds a short, plain-text excerpt of a longer text. Line breaks are allowed and
# are treated as sentence boundaries.
#
# Declare `has_excerpt :attr` to generate an `#{attr}_excerpt` method. The raw
# attribute value is always run through #to_plain_text (html2text) first, so it
# works for both HTML and plain-text attributes. A nil attribute yields nil.
#
# @example
#   has_excerpt :note
#   has_excerpt :body
module HasExcerpt
  extend ActiveSupport::Concern

  EXCERPT_WORD_TARGET = 50
  EXCERPT_WORD_CAP    = 60

  # Convert HTML to plain text via String#html2text: block elements become line
  # breaks, links keep their text (link_style: :plain), and entities are decoded.
  # Plain-text input is returned essentially unchanged.
  def self.to_plain_text(raw)
    raw.to_s.html2text(link_style: :plain)
  end

  class_methods do
    def has_excerpt(*attrs) # rubocop:disable Naming/PredicatePrefix
      attrs.each do |attr|
        define_method :"#{attr}_excerpt" do |**options|
          raw = send(attr)
          return if raw.nil?

          excerpt_text(HasExcerpt.to_plain_text(raw), **options)
        end
      end
    end
  end

  # Plain-text excerpt of the given text, roughly word_target words long. Whole
  # sentences are kept so the excerpt never ends mid-sentence, line breaks are
  # preserved, and an ellipsis is appended when the text was truncated.
  #
  # word_cap is a hard upper bound: a single very long sentence (e.g. the one that
  # crosses the target) is truncated mid-sentence so the excerpt never exceeds
  # word_cap words.
  def excerpt_text(text, word_target: EXCERPT_WORD_TARGET, word_cap: EXCERPT_WORD_CAP)
    text = excerpt_normalize_text(text)
    return text if text.blank?

    sentences = excerpt_split_sentences(text)

    kept      = []
    words     = 0
    truncated = false

    sentences.each do |sentence, line_index|
      remaining = word_cap - words
      if remaining <= 0
        truncated = true
        break
      end

      sentence_words = sentence.split
      if sentence_words.size > remaining
        # Cap an over-long sentence so the excerpt stays within word_cap words.
        sentence  = sentence_words.first(remaining).join(' ')
        truncated = true
      end

      kept << [sentence, line_index]
      words += [sentence_words.size, remaining].min

      break if truncated || words >= word_target
    end

    excerpt = excerpt_join_sentences(kept)
    excerpt += ' …' if truncated || kept.size < sentences.size
    excerpt
  end

  private

  # Collapse runs of spaces/tabs while keeping line breaks, trim spaces hugging a
  # line break, and collapse long runs of blank lines.
  def excerpt_normalize_text(text)
    text.to_s
      .gsub(%r{[^\S\n]+}, ' ')
      .gsub(%r{ *\n *}, "\n")
      .gsub(%r{\n{3,}}, "\n\n")
      .strip
  end

  # Flatten to (sentence, line index) pairs so line breaks can be restored later.
  # A line break counts as a sentence boundary even without terminating punctuation.
  def excerpt_split_sentences(text)
    text.split("\n", -1).each_with_index.flat_map do |line, line_index|
      next [['', line_index]] if line.empty?

      line.scan(%r{\S.*?(?:[.!?]+(?=\s|\z)|\z)}).map { |sentence| [sentence, line_index] }
    end
  end

  # Re-join kept (sentence, line index) pairs, using a newline between sentences
  # from different source lines and a single space within the same line.
  def excerpt_join_sentences(kept)
    kept.each_with_index.map do |(sentence, line_index), index|
      separator = index.zero? || line_index == kept[index - 1][1] ? ' ' : "\n"
      index.zero? ? sentence : "#{separator}#{sentence}"
    end.join
  end
end
