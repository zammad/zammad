# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  class ReplaceInlineImages
    def sanitize(string, prefix)
      scrubber = HtmlSanitizer::Scrubber::InlineImages.new(prefix)

      sanitized = ScrubHtml.new(string, [scrubber]).scrub!

      [sanitized.to_html, scrubber.attachments_inline]
    end
  end
end
