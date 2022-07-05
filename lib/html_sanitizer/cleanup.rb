# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  class Cleanup < Base
    def sanitize(string, timeout: true)
      return run_sanitization(string) if !timeout

      with_timeout(string) do
        run_sanitization(string)
      end
    end

    private

    def run_sanitization(string)
      string = clean_string(string)

      string = cleanup_structure(string, 'pre')

      cleanup_structure(string)
    end

    def clean_string(input)
      output = input.gsub(%r{<(|/)[A-z]:[A-z]>}, '')

      output = output.delete("\t")
      # remove all new lines
      output
        .gsub(%r{(\n\r|\r\r\n|\r\n|\n)}, "\n")
        .gsub(%r{\n\n\n+}, "\n\n")
    end

    def cleanup_structure(string, type = 'all')
      empty_node_scrubber = HtmlSanitizer::Scrubber::RemoveLastEmptyNode.new(type)

      string = loop(string, empty_node_scrubber)

      Loofah.fragment(string).scrub!(HtmlSanitizer::Scrubber::Cleanup.new).to_html
    end
  end
end
