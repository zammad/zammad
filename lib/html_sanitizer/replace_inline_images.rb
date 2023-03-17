# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  class ReplaceInlineImages
    def sanitize(string, prefix)
      scrubber = HtmlSanitizer::Scrubber::InlineImages.new(prefix)

      sanitized = Loofah
        .fragment(string)
        .scrub!(scrubber)

      [sanitized.to_html, scrubber.attachments_inline]
    end
  end
end
