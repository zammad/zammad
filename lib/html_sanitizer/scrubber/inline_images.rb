# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  module Scrubber
    class InlineImages < Base
      attr_reader :attachments_inline, :prefix

      def initialize(prefix = SecureRandom.uuid) # rubocop:disable Lint/MissingSuper
        @direction = :top_down

        @attachments_inline = []
        @prefix             = prefix
      end

      def scrub(node)
        return CONTINUE if node.name != 'img'

        if node['src'] && node['src'] =~ %r{^(data:image/(jpeg|png);base64,.+?)$}i
          process_inline_image(node, $1)
        end

        STOP
      end

      private

      def inline_image_data(src)
        return if src.blank?

        matchdata = src.match %r{^(data:image/(jpeg|png);base64,.+?)$}i

        return if !matchdata

        matchdata[0]
      end

      def process_inline_image(node, data)
        cid        = generate_cid
        attachment = parse_inline_image(data, cid)

        @attachments_inline.push attachment
        node['src'] = "cid:#{cid}"
      end

      def parse_inline_image(data, cid)
        file_attributes = StaticAssets.data_url_attributes(data)
        filename        = "image#{@attachments_inline.length + 1}.#{file_attributes[:file_extention]}"

        {
          data:        file_attributes[:content],
          filename:    filename,
          preferences: {
            'Content-Type'        => file_attributes[:mime_type],
            'Mime-Type'           => file_attributes[:mime_type],
            'Content-ID'          => cid,
            'Content-Disposition' => 'inline',
          }
        }
      end

      def generate_cid
        "#{prefix}.#{SecureRandom.uuid}@#{fqdn}"
      end

      def fqdn
        @fqdn ||= Setting.get('fqdn')
      end
    end
  end
end
