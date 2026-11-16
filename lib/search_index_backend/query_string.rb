# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Rebuilds the boolean structure of a query string as a bool query, so that its parts get conditions of their own.
class SearchIndexBackend::QueryString
  class Unparsable < StandardError; end

  Text = Struct.new(:query)

  GROUPS_MAX  = 100
  SPACE       = %r{[ \t\n\r\u3000]}
  SPACES      = %r{#{SPACE}+}
  CHAR        = %r{\\.|[^ \t\n\r\u3000+\-!():^\[\]"\{\}~*?\\/]}m
  WORD_CHAR   = %r{#{CHAR}|[*?+-]}
  WORD        = %r{(?:#{CHAR}|[*?])(?:#{WORD_CHAR})*}
  PHRASE      = %r{"(?:\\.|[^"\\])*"}m
  RANGE       = %r{[\[\{][^\]\}]*[\]\}]}
  REGEXP      = %r{/(?:\\/|[^/])*/}
  BOOST       = %r{\^\d+(?:\.\d+)?}
  TERM        = %r{(?:#{WORD}|#{PHRASE}|#{RANGE}|#{REGEXP})(?:#{SPACE}*(?:#{BOOST}|~(?:#{CHAR}|[+-])*))*}
  FIELD       = %r{(#{WORD})#{SPACE}*:#{SPACE}*}
  GROUP_START = %r{\(}
  GROUP_END   = %r{\)(?:#{SPACE}*#{BOOST})?}
  CONJUNCTION = %r{(?:(AND|&&)|OR|\|\|)(?!#{WORD_CHAR})}
  PROHIBITED  = %r{NOT(?!#{WORD_CHAR})|[!-](?!#{SPACE})}
  REQUIRED    = %r{\+(?!#{SPACE})}
  OPERATOR    = %r{[+!-](?=#{SPACE})}

  attr_reader :query, :scanner, :groups

  def initialize(query)
    @query = query
  end

=begin

returns the bool query, the block gets each part of the query and returns its condition

  SearchIndexBackend::QueryString.new('printer toner !state.name:closed').to_bool { |part| { query_string: { query: part } } }

returns

  {
    bool: {
      must:     [{ query_string: { query: 'printer AND toner' } }],
      must_not: [{ query_string: { query: 'state.name:closed' } }],
    }
  }

A part is a term with a field, a prohibited or an optional term, or all other required terms of a group. A group without
fields and prohibited terms counts as a term, inside of a prohibited group every term is a part. A query without fields
and prohibited terms, or one which can not be parsed, is one part.

=end

  def to_bool(&)
    @scanner = StringScanner.new(query)
    @groups  = 0

    condition = parse(nil, false, &)
    raise Unparsable if !scanner.eos?

    condition || yield(query)
  rescue Unparsable
    yield query
  end

  private

  def parse(field, split, &)
    clauses = []
    started = false

    loop do
      scanner.skip(SPACES)
      break if scanner.eos? || scanner.check(GROUP_END)

      occur = conjunction
      raise Unparsable if occur && !started

      started    = true
      prohibited = modifier
      add(clauses, occur, prohibited, clause(field, split || prohibited, &))
    end

    bool(clauses, &)
  end

  def conjunction
    return if !scanner.skip(CONJUNCTION)

    occur = scanner[1] ? :must : :should
    scanner.skip(SPACES)
    occur
  end

  def modifier
    prohibited = !scanner.skip(PROHIBITED).nil?
    scanner.skip(REQUIRED) if !prohibited
    scanner.skip(SPACES)
    prohibited
  end

  def clause(field, split, &)
    start = scanner.pos
    own   = scanner.skip(FIELD)
    field = scanner[1] if own

    return group(field, split, start, &) if scanner.skip(GROUP_START)
    return if scanner.skip(OPERATOR)
    raise Unparsable if !scanner.skip(TERM)

    term = query.byteslice(start...scanner.pos)
    return Text.new(term) if !field && !split

    yield(own || !field ? term : "#{field}:#{term}")
  end

  def group(field, split, start, &)
    @groups += 1
    raise Unparsable if groups > GROUPS_MAX

    condition = parse(field, split, &)
    raise Unparsable if !scanner.skip(GROUP_END)

    condition || Text.new(query.byteslice(start...scanner.pos))
  end

  # The occur of a clause follows the query parser of Lucene, an operator also changes the clause before.
  def add(clauses, occur, prohibited, clause)
    clauses.last[0] = occur if occur && clauses.present? && clauses.last[0] != :must_not
    return if !clause

    clauses.push([prohibited ? :must_not : occur || :must, clause])
  end

  def bool(clauses, &)
    raise Unparsable if clauses.blank?
    return if clauses.all? { |occur, clause| occur != :must_not && clause.is_a?(Text) }

    clauses = conditions(join(clauses), &)
    occur, condition = clauses.first
    return condition if clauses.one? && occur != :must_not

    { bool: clauses.group_by(&:first).transform_values { |list| list.map(&:last) } }
  end

  def join(clauses)
    texts, clauses = clauses.partition { |occur, clause| occur == :must && clause.is_a?(Text) }
    return clauses if texts.blank?

    clauses.unshift([:must, Text.new(texts.map { |_occur, text| text.query }.join(' AND '))])
  end

  def conditions(clauses)
    clauses.map { |occur, clause| [occur, clause.is_a?(Text) ? yield(clause.query) : clause] }
  end
end
