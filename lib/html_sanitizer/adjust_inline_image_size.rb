# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  class AdjustInlineImageSize
    def sanitize(string)
      return string if string.exclude? '<img'

      scrubber = HtmlSanitizer::Scrubber::Outgoing::ImageSize.new

      return Loofah.scrub_document(string, scrubber).to_html if string.include? '<html'

      Loofah.fragment(string).scrub!(scrubber).to_html
    end
  end
end
