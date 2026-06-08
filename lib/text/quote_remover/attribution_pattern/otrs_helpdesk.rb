# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Text::QuoteRemover::AttributionPattern::OtrsHelpdesk < Text::QuoteRemover::AttributionPattern
  def self.pattern
    # OTRS-style: "25.02.2015 10:26 - edv hotline wrote:"
    # Reuses WROTE_VERBS from Wrote pattern for 27 language support
    %r{^.{6,10}[[:space:]].{3,10}[[:space:]]-[[:space:]].{1,250}[[:space:]](#{Wrote::WROTE_VERBS}):}io
  end
end
