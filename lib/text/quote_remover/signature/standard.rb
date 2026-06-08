# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Text::QuoteRemover::Signature::Standard < Text::QuoteRemover::Signature
  # Standard email signature delimiter: "-- " or "--" on its own line.
  # The RFC 3676 specifies "-- " (dash dash space) but many clients use just "--".

  DELIMITER_PATTERN = %r{\A--[[:blank:]]*\z}

  def self.match?(line)
    line.strip.match?(DELIMITER_PATTERN)
  end
end
