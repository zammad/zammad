# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  module Scrubber
    class Base < Loofah::Scrubber
      HTML_DECODABLE = {
        '&amp;'  => '&',
        '&lt;'   => '<',
        '&gt;'   => '>',
        '&quot;' => '"',
        '&nbsp;' => ' '
      }.freeze

      HTML_DECODABLE_REGEXP = Regexp.union(HTML_DECODABLE.keys).freeze

      protected

      def html_decode(string)
        string.gsub HTML_DECODABLE_REGEXP, HTML_DECODABLE
      end
    end
  end
end
