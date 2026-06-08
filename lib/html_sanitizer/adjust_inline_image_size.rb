# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  class AdjustInlineImageSize
    def sanitize(string)
      return string if string.exclude? '<img'

      scrubber = HtmlSanitizer::Scrubber::Outgoing::ImageSize.new

      chunk = string.include?('<html') ? :document : :fragment

      ScrubHtml.new(string, scrubber, chunk:).scrub!.to_html
    end
  end
end
