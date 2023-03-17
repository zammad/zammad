# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  module Scrubber
    class QuoteContent < Base
      def scrub(node)
        return if tags_quote_content.exclude?(node.name)

        string = html_decode(node.content)
        text = Nokogiri::XML::Text.new(string, node.document)
        node.add_next_sibling(text)
        node.remove

        STOP
      end

      private

      def tags_quote_content
        @tags_quote_content ||= Rails.configuration.html_sanitizer_tags_quote_content
      end
    end
  end
end
