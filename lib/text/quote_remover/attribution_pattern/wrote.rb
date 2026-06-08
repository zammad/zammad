# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Text::QuoteRemover::AttributionPattern::Wrote < Text::QuoteRemover::AttributionPattern
  # "Wrote" verb in various languages
  # Matches patterns like "John wrote:", "Am 24.10.2016 schrieb John:", etc.
  WROTE_VERBS = [
    'wrote',
    'schrieb',
    'a écrit',
    'escribió',
    'escreveu',
    'написал',
    'skrev',
    'kirjoitti',
    'viết',
    'ha scritto',
    'schreef',
    'napisał',
    'napsal',
    'yazdı',
    'написа',
    'írta',
    'написав',
    'napisao',
    'napísal',
    'napisal',
    'написао',
    'a scris',
    'parašė',
    'rašė',
    'rakstīja',
    'kirjutas',
    'skrifaði',
    'έγραψε'
  ].join('|').freeze

  def self.pattern
    # Example: "John Smith wrote:" or "Am 24.10.2016 18:55 schrieb John:" or "Nicole Braun rašė:"
    # Some languages put the colon directly after the verb (rašė:)
    %r{.{1,250}[[:space:]](#{WROTE_VERBS})([[:space:]].{0,250})?:}io
  end
end
