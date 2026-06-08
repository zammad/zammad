# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Text::QuoteRemover::AttributionPattern::OutlookDelimiter < Text::QuoteRemover::AttributionPattern
  # Delimiter characters used by various email clients
  # Note: We require 5+ characters to avoid matching "-- " signature delimiters
  DELIMITER_CHARACTERS = '-_=+~#*ᐧ—'.freeze

  def self.pattern
    # Line containing only delimiter characters (at least 5 to avoid signature delimiters)
    # Examples: "________________________________", "-----", "*****", "======"
    %r{^[[:blank:]]*[#{Regexp.escape(DELIMITER_CHARACTERS)}]{5,}[[:blank:]]*$}o
  end
end
