# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Text::QuoteRemover::AttributionPattern::IsoDateWrote < Text::QuoteRemover::AttributionPattern
  # ISO date format with timezone and name/email
  # Example: "2016-03-03 17:21 GMT+01:00 Some One"
  # Example: "2015-10-18 0:17 GMT+03:00 Matt Palmer <info@discourse.org>:"

  def self.pattern
    %r{
      # 2016-03-03 17:21 GMT+01:00 Some One
      ^[[:blank:]>]*20\d\d-\d\d-\d\d\ \d\d?:\d\d\ GMT[+-]\d\d:\d\d\ [\w[:blank:]]+$
      |
      # 2015-10-18 0:17 GMT+03:00 Matt Palmer <info@discourse.org>:
      \d{4}.{1,80}\s?<[^@<>]+@[^@<>.]+\.[^@<>]+>:?$
    }ix
  end
end
