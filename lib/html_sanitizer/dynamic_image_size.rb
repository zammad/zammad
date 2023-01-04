# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  class DynamicImageSize
    def sanitize(string)
      Loofah
        .fragment(string)
        .scrub!(HtmlSanitizer::Scrubber::ImageSize.new)
        .to_html
    end
  end
end
