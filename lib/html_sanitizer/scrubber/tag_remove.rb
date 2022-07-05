# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  module Scrubber
    class TagRemove < Base
      def scrub(node)
        return if tags_remove_content.exclude?(node.name)

        node.remove
        STOP
      end

      private

      def tags_remove_content
        Rails.configuration.html_sanitizer_tags_remove_content
      end
    end
  end
end
