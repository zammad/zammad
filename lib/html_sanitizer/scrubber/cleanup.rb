# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  module Scrubber
    class Cleanup < Base
      def scrub(node)
        return if !node.instance_of?(Nokogiri::XML::Text)
        return if %w[pre code].include? node.parent&.name

        update_node_content(node)
      end

      private

      def update_node_content(node)
        content = node.content

        return if !content

        content = remove_space_if_needed(content)
        content = strip_if_needed_previous(node, content)
        content = strip_if_needed_next(node, content)

        node.content = content
      end

      def remove_space_if_needed(content)
        return content if space_or_nl?(content)

        # https://github.com/zammad/zammad/issues/4223
        # We are converting multiple line breaks into a more readable format.
        #   All other whitespace is treated as a single space character.
        content.gsub(%r{[[:space:]]+}) do |match|
          match.include?("\n\n") ? "\n\n" : ' '
        end
      end

      def strip_if_needed_previous(node, content)
        return content if !node.previous
        return content if !div_or_p?(node.previous)

        content.strip
      end

      def strip_if_needed_next(node, content)
        return content if !node.parent
        return content if node.previous
        return content if node.next && %w[div p br].exclude?(node.next.name)

        return content if !div_or_p?(node.parent)
        return content if space_or_nl?(content)

        content.strip
      end

      def space_or_nl?(string)
        [' ', "\n"].include?(string)
      end

      def div_or_p?(node)
        %w[div p].include? node.name
      end
    end
  end
end
