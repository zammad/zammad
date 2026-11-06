# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Whether a query holds a word to look for at all, whether it names a field, and its words without Elasticsearch's
#   query syntax, for a search that does not take the syntax. A quote, a bracket or a slash makes the whole search fail; a wildcard, a field name
#   or a leading minus, or an upper-case AND, OR or NOT changes what it means — a lone "?" lists every record. None of
#   them is a word to look for, nor is a query of the database's wildcards alone.
module Service::AI::Tool::Search::QueryWords
  SYNTAX    = %r{["()\[\]{}/\\:^~!<>=&|?*+]|(?<![[:alnum:]])-}
  OPERATORS = %r{\b(?:AND|OR|NOT)\b}

  # The database's wildcards, which a search without Elasticsearch could read as such.
  WILDCARDS = %r{[%_]}

  # A field with its value, as in title:printer or created_at:>now-1d, not a colon in a sentence, a time or a link.
  FIELD = %r{(?<![[:alnum:]_.])[[:alpha:]][[:alnum:]_.]*:(?!//)\S}

  # @return [String] the words, empty where the text held nothing but syntax
  def self.without_syntax(text)
    text.to_s.gsub(SYNTAX, ' ').gsub(OPERATORS, ' ').squish
  end

  # Whether the text holds a word to look for: not only syntax or the database's wildcards. A quoted phrase is one, also
  #   where it is an operator such as "OR".
  def self.words?(text)
    without_syntax(text).gsub(WILDCARDS, '').present? || text.to_s.scan(%r{"([^"]*)"}).flatten.any? { |phrase| phrase.match?(%r{[[:alnum:]]}) }
  end

  # Models like to quote their words; the database would then look for the quotes.
  IGNORED_CHARACTERS = '"“”„«»*'.freeze

  # The query as a search takes it: with Elasticsearch in Zammad's search syntax, as the search box does; without it,
  #   the words as they stand.
  #
  # @return [String, nil] none where the text holds no word to look for
  def self.search_text(text)
    text = text.to_s.squish
    return if !words?(text)

    SearchIndexBackend.enabled? ? text : text.delete(IGNORED_CHARACTERS).squish
  end

  # Whether the text names a field, which only Elasticsearch searches.
  def self.field?(text)
    text.to_s.match?(FIELD)
  end
end
