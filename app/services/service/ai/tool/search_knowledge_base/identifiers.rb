# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The identifiers in a query — error codes, version strings, order numbers — which a search by meaning loses, so the
#   keyword search looks for them as well. Narrow on purpose: a word that only looks technical ("VPN", "full-page") or a
#   year would pull in every answer that mentions it.
module Service::AI::Tool::SearchKnowledgeBase::Identifiers
  PATTERNS = [
    # Letters and digits mixed, at least four: RTX4090, 0x8004010F.
    %r{\b(?=[a-z0-9]*[a-z])(?=[a-z0-9]*\d)[a-z0-9]{4,}\b}i,
    # Parts joined by - _ or ., with a digit or an underscore: ERR-4032, SSL_ERROR_SYSCALL, v2.1.3. Not by a slash, which
    #   Elasticsearch's query syntax reads as the start of a regular expression.
    %r{\b[a-z0-9]+(?:[-_.][a-z0-9]+)+\b}i,
    # Long digit runs, longer than a year: 1005678.
    %r{\b\d{5,}\b},
  ].freeze

  MAX = 3

  # @return [Array<String>] at most three identifiers, in the order of the query
  def self.in(query)
    tokens = PATTERNS
      .flat_map { |pattern| query.to_s.to_enum(:scan, pattern).map { [Regexp.last_match(0), Regexp.last_match.begin(0)] } }
      .select { |token, _position| token.match?(%r{[\d_]}) }
      .sort_by(&:last)
      .map(&:first)
      .uniq(&:downcase)

    # "INC-2041" also matches as "2041", which only adds a weaker word for the same identifier.
    tokens
      .reject { |token| tokens.any? { |other| other.length > token.length && other.downcase.include?(token.downcase) } }
      .first(MAX)
  end
end
