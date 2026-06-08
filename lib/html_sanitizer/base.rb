# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  class Base
    def with_timeout(string, &)
      Timeout.timeout(PROCESSING_TIMEOUT, &)
    rescue Timeout::Error
      Rails.logger.error "Could not process string via #{self.class.name} in #{PROCESSING_TIMEOUT} seconds. Current state: #{string}"
      UNPROCESSABLE_HTML_MSG
    rescue => e
      return UNPROCESSABLE_HTML_MSG if e.is_a?(ArgumentError) && e.message == 'Document tree depth limit exceeded'

      raise e
    end

    def loop_string(string, scrubber)
      string = ScrubHtml.new(string, scrubber).scrub!.to_html
      old_string = string

      loop do
        string = ScrubHtml.new(string, scrubber).scrub!.to_html
        break if string == old_string

        old_string = string
      end

      string
    end
  end
end
