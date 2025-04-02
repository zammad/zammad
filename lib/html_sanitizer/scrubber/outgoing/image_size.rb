# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  module Scrubber
    module Outgoing
      class ImageSize < Base
        def scrub(node)
          return CONTINUE if node.name != 'img'
          return CONTINUE if node['style'].blank?

          adjust(node, 'height')
          adjust(node, 'width')

          STOP
        end

        private

        def split_style(node)
          node['style'].downcase.gsub(%r{\t|\n|\r}, '').split(';')
        end

        def adjust(node, key)
          return if node[key].present?

          split_style(node).each do |elem|
            attr, value = elem.split(':')

            attr.strip!
            value.strip!

            next if attr != key
            next if !value.downcase.ends_with?('px')

            node[key] = value.include?('.') ? value.to_f : value.to_i
          end
        end
      end
    end
  end
end
