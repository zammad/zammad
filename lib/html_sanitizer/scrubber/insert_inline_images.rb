# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  module Scrubber
    class InsertInlineImages < Base
      attr_reader :attachments

      def initialize(attachments)
        @attachments = attachments

        super()
      end

      def scrub(node)
        return CONTINUE if !contains_inline_images?(node)

        attachment = matching_attachment(node)
        return CONTINUE if !attachment

        node.delete('cid')
        node['src'] = base64_data_url(attachment)
      end

      private

      def matching_attachment(node)
        node_cids = inline_images_cids(node)

        attachments.find do |elem|
          attachment_cid = elem.preferences&.dig('Content-ID')

          node_cids.include?(attachment_cid)
        end
      end

      def contains_inline_images?(node)
        return false if node.name != 'img'
        return false if !node['src']&.start_with?('cid:')

        true
      end

      def inline_images_cids(node)
        cid = node['src'].delete_prefix('cid:')

        [cid, "<#{cid}>"]
      end

      def base64_data_url(attachment)
        "data:#{attachment.preferences['Content-Type']};base64,#{Base64.strict_encode64(attachment.content)}"
      end
    end
  end
end
