# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  module Scrubber
    class ImageSize < Base
      def scrub(node)
        return CONTINUE if node.name != 'img'

        if node['src']
          update_style(node)
        end

        STOP
      end

      private

      def update_style(node)
        node['style'] = build_style(node['style'])
      end

      def build_style(input)
        style = 'max-width:100%;'

        return style if input.blank?

        input
          .downcase
          .gsub(%r{\t|\n|\r}, '')
          .split(';')
          .each_with_object(style) do |elem, memo|
            key, value = elem.split(':')

            key.strip!

            next if key.blank?

            key = 'max-height' if key == 'height'

            memo << "#{key}:#{value};"
          end
      end
    end
  end
end
