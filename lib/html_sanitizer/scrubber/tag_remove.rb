# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  module Scrubber
    class TagRemove < Base
      # @param tags [Array<String,Symbol>] list of tags to remove. Defaults to .tags_remove_content
      def initialize(tags: nil)
        super()

        @tags = tags || self.class.tags_remove_content
      end

      def scrub(node)
        return if @tags.exclude?(node.name)

        node.remove
        STOP
      end

      def self.tags_remove_content
        Rails.configuration.html_sanitizer_tags_remove_content
      end
    end
  end
end
