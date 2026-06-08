# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Text::QuoteRemover::AttributionPattern::AngleBracketQuote < Text::QuoteRemover::AttributionPattern
  def self.pattern
    # Lotus Notes / older email client style quote attribution
    # Example: ">>> Ivan Perović via Zammad Helpdesk <support@zammad.com> 02.12.2025 14:22 >>>"
    # Pattern: >>> ... >>> or >> ... >>
    %r{^>{2,3}\s*.+\s*>{2,3}\s*$}
  end
end
