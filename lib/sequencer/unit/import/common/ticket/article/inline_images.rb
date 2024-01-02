# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Ticket::Article::InlineImages < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :mapped, :instance

  def process
    check_for_existing_instance
    return if !contains_inline_image?(mapped[:body])

    replaced_body = replaced_inline_images
    (replaced_body, inline_attachments) = HtmlSanitizer.replace_inline_images(replaced_body, mapped[:ticket_id])

    provide_mapped do
      {
        body:        replaced_body.strip,
        attachments: inline_attachments,
      }
    end
  end

  def self.inline_data(image_url)
    clean_image_url = image_url.gsub(%r{^cid:}, '')
    return if !%r{^(http|https)://.+?$}.match?(clean_image_url)

    @cache ||= {}
    return @cache[clean_image_url] if @cache[clean_image_url]

    image_data = download(clean_image_url)
    return if image_data.blank?

    @cache[clean_image_url] = "data:image/png;base64,#{Base64.strict_encode64(image_data)}"
    @cache[clean_image_url]
  end

  def self.download(image_url)
    logger.debug { "Downloading inline image from #{image_url}" }

    response = UserAgent.get(
      image_url,
      {},
      {
        open_timeout: 20,
        read_timeout: 240,
        verify_ssl:   true,
      },
    )

    return response.body if response.success?

    logger.error response.error
    nil
  end

  private

  def contains_inline_image?(string)
    return false if string.blank?

    string.include?(inline_image_url_prefix)
  end

  def replaced_inline_images
    body_html = Nokogiri::HTML(mapped[:body])

    body_html.css('img').each do |node|
      next if !contains_inline_image?(node['src'])

      node.attributes['src'].value = self.class.inline_data(node['src'])
    end

    body_html.to_html
  end

  def check_for_existing_instance
    return if instance.blank? || local_inline_attachments.blank?

    local_inline_attachments.each(&:delete)
  end

  def local_inline_attachments
    @local_inline_attachments ||= instance.attachments&.filter { |attachment| attachment.preferences&.dig('Content-Disposition') == 'inline' }
  end

  def inline_image_url_prefix
    raise NotImplementedError
  end
end
