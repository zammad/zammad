# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A word as the tools search for it in a text: whole, in any case. A name joined by hyphens, dots or underscores, also
#   several in a row, is one word, so that "ERR-4032" is not found in "ERR-40321", "ERR-4032-10", "MAIL-ERR-4032" or
#   "MAIL--ERR-4032", but at the end of a sentence it is.
module Service::AI::Tool::Search::WholeWord
  # @return [Array<String>] the words of a query, without the quotes, stars and punctuation around each; hyphens and
  #   dots inside a word stay
  def self.words(query)
    query.to_s.split
      .map { |word| word.gsub(%r{\A[^[:alnum:]]+|[^[:alnum:]]+\z}, '') }
      .compact_blank
      .uniq(&:downcase)
  end

  # @return [Boolean]
  def self.in?(text, word)
    text.to_s.match?(pattern(word))
  end

  # The text before the word is matched and dropped (\K) rather than looked behind at: a look-behind holds no run of
  #   separators, and one in any case fails on a text with other than ASCII letters.
  #
  # @return [Regexp] the word itself, in any case
  def self.pattern(word)
    %r{(?:\A|[^[:alnum:]\-_.]|(?:\A|[^[:alnum:]\-_.])[-_.]+)\K(?i:#{Regexp.escape(word)})(?![-_.]*[[:alnum:]])}
  end
end
