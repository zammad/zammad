# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Reads a translated section: bold and italic Markdown, markers, line breaks and text. Only `**`
# and `*` are formatting, everything else the model writes stays text.
class ContentTranslation::Html::Markdown
  MARKER = %r{\{(?:/[1-9]\d*|[1-9]\d*/?)\}}

  # A run of asterisks, opening on its right and closing on its left side.
  Delimiter = Struct.new(:remaining, :opens, :closes, :opened, :closed)

  # @return [Array<Array>] `[type, value]` pairs of :text, :break, :open, :close, :marker_open,
  #   :marker_close and :placeholder
  def self.tokens(text)
    items = scan(text)
    match(items.grep(Delimiter))

    items.flat_map { |item| item.is_a?(Delimiter) ? delimiter_tokens(item) : [item] }
  end

  def self.scan(text)
    scanner = StringScanner.new(text)
    items   = []

    until scanner.eos?
      items << if scanner.scan(%r{\\([!-/:-@\[-`\{-~])})
                 [:text, scanner[1]]
               elsif scanner.scan(MARKER)
                 marker_token(scanner.matched)
               elsif scanner.scan(%r{[{}]})
                 raise ContentTranslation::Html::InvalidTranslation
               elsif scanner.scan(%r{\*+})
                 delimiter(text, scanner)
               elsif scanner.scan(%r{\n})
                 [:break]
               else
                 [:text, scanner.scan(%r{\\|[^\\{}*\n]+})]
               end
    end

    items
  end

  # Unlike CommonMark, a delimiter next to punctuation or a marker still counts, so the model can
  # place emphasis anywhere a word boundary allows it.
  def self.delimiter(text, scanner)
    start  = scanner.charpos - scanner.matched.length
    before = text[start - 1] if start.positive?
    after  = text[scanner.charpos]

    Delimiter.new(scanner.matched.length, !blank?(after), !blank?(before), [], [])
  end

  def self.blank?(character)
    character.nil? || character.match?(%r{[[:space:]]})
  end

  # Closes the innermost open emphasis first; two asterisks on both sides are bold, one is italic.
  # A run that could also open, like the one in `**read (*this*)**`, does not close a longer one.
  def self.match(delimiters)
    openers = []

    delimiters.each do |delimiter|
      while delimiter.closes && delimiter.remaining.positive? && (opener = openers.last) &&
            (!delimiter.opens || opener.remaining <= delimiter.remaining)
        used = [opener.remaining, delimiter.remaining].min >= 2 ? 2 : 1
        tag  = used == 2 ? 'strong' : 'em'

        opener.opened.unshift(tag)
        delimiter.closed << tag
        opener.remaining    -= used
        delimiter.remaining -= used

        openers.pop if opener.remaining.zero?
      end

      openers << delimiter if delimiter.opens && delimiter.remaining.positive?
    end
  end

  def self.delimiter_tokens(delimiter)
    [
      *delimiter.closed.map { |tag| [:close, tag] },
      *([[:text, '*' * delimiter.remaining]] if delimiter.remaining.positive?),
      *delimiter.opened.map { |tag| [:open, tag] },
    ]
  end

  def self.marker_token(marker)
    number = marker.delete('{}/')

    if marker.start_with?('{/')
      [:marker_close, number]
    elsif marker.end_with?('/}')
      [:placeholder, number]
    else
      [:marker_open, number]
    end
  end

  private_class_method :scan, :delimiter, :blank?, :match, :delimiter_tokens, :marker_token
end
