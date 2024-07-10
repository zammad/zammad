# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
        return CONTINUE if node['src'].blank?

        case node['src']
        when %r{^(data:image/(jpeg|png);base64,.+?)$}i
          process_inline_image(node, $1)
        when %r{^(?:/api/v1/attachments/)(\d+)$}
          process_uploaded_image(node, $1)
        when %r{users/image/(.+)}
          process_user_avatar_image(node, $1)
        when %r{^(?:blob:)}
          node.remove
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

      def process_uploaded_image(node, attachment_id)
        cid        = generate_cid
        attachment = Store.find(attachment_id)

        @attachments_inline.push attachment(attachment.content, attachment.filename, cid, mime_type: attachment.preferences['Mime-Type'], content_type: attachment.preferences['Content-Type'])
        node['src'] = "cid:#{cid}"
      end

      def process_user_avatar_image(node, image_hash)
        return if !node['data-user-avatar']
        return if image_hash.blank?

        cid = generate_cid
        file = avatar_file(image_hash)

        return if file.nil?

        @attachments_inline.push attachment(file.content, file.filename, cid, mime_type: file.preferences['Mime-Type'], content_type: file.preferences['Content-Type'])
        node['src'] = "cid:#{cid}"
      end

      def parse_inline_image(data, cid)
        file_attributes = ImageHelper.data_url_attributes(data)
        filename        = "image#{@attachments_inline.length + 1}.#{file_attributes[:file_extention]}"

        attachment(
          file_attributes[:content],
          filename,
          cid,
          mime_type: file_attributes[:mime_type],
        )
      end

      def attachment(content, filename, cid, mime_type: nil, content_type: nil)
        {
          data:        content,
          filename:    filename,
          preferences: {
            'Content-Type'        => content_type || mime_type,
            'Mime-Type'           => mime_type || content_type,
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

      def avatar_file(image_hash)
        Avatar.get_by_hash(image_hash)
      rescue
        nil
      end
    end
  end
end
