# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  class DynamicImageSize
    def sanitize(string)
      ScrubHtml.new(string, HtmlSanitizer::Scrubber::ImageSize.new).scrub!.to_html
    end
  end
end
