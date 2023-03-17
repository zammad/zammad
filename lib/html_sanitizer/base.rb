# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  class Base
    def with_timeout(string, &)
      Timeout.timeout(PROCESSING_TIMEOUT, &)
    rescue Timeout::Error
      Rails.logger.error "Could not process string via #{self.class.name} in #{PROCESSING_TIMEOUT} seconds. Current state: #{string}"
      UNPROCESSABLE_HTML_MSG
    end

    def loop_string(string, scrubber)
      string = Loofah.fragment(string).scrub!(scrubber).to_html
      old_string = string

      loop do
        string = Loofah.fragment(string).scrub!(scrubber).to_html
        break if string == old_string

        old_string = string
      end

      string
    end
  end
end
