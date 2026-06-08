# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Text::QuoteRemover::AttributionPattern::PostedBy < Text::QuoteRemover::AttributionPattern
  # "Posted by someone on date" pattern
  # Example: "Posted by mpalmer on 01/21/2016"

  def self.pattern
    %r{^[[:blank:]>]*Posted by .+ on \d{2}/\d{2}/\d{4}$}i
  end
end
