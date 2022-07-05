# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  class Base
    def with_timeout(string, &block)
      Timeout.timeout(PROCESSING_TIMEOUT, &block)
    rescue Timeout::Error
      Rails.logger.error "Could not process string via #{self.class.name} in #{PROCESSING_TIMEOUT} seconds. Current state: #{string}"
      UNPROCESSABLE_HTML_MSG
    end

    def loop(string, scrubber)
      old_string = nil

      while string != old_string
        old_string = string

        string = Loofah.fragment(string).scrub!(scrubber).to_html
      end

      string
    end
  end
end
