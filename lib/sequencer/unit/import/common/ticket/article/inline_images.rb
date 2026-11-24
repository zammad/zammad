# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Ticket::Article::InlineImages < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :mapped, :instance

  INLINE_DATA_CACHE_SIZE = 64.megabytes

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

  def self.inline_data(image_url, log_context: {})
    clean_image_url = image_url.gsub(%r{^cid:}, '')
    return if !http_url?(clean_image_url, log_context)

    inline_data_cache.fetch(clean_image_url, skip_nil: true) do
      image_data = download(clean_image_url)
      "data:image/png;base64,#{Base64.strict_encode64(image_data)}" if image_data.present?
    end
  end

  # An import runs for days in the same process, so the cache must not grow with the number of images.
  def self.inline_data_cache
    @inline_data_cache ||= ActiveSupport::Cache::MemoryStore.new(size: INLINE_DATA_CACHE_SIZE)
  end
  private_class_method :inline_data_cache

  def self.download(image_url)
    logger.debug { "Downloading inline image from #{image_url}" }

    response = UserAgent.get(
      image_url,
      {},
      {
        read_timeout:  ENV.fetch('ZAMMAD_HTTP_IMPORT_ATTACHMENT_READ_TIMEOUT', 240).to_i,
        total_timeout: ENV.fetch('ZAMMAD_HTTP_IMPORT_ATTACHMENT_TOTAL_TIMEOUT', 240).to_i,
        verify_ssl:    true,
      },
    )

    return response.body if response.success?

    logger.error response.error
    nil
  end

  def self.http_url?(url, log_context)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    # The URL is left out of the message, as it may contain an access token.
    context = log_context.compact.map { |key, value| "#{key}: #{value}" }.join(', ')
    logger.warn "Skipping inline image, its URL is not a valid URI (#{context})."
    false
  end
  private_class_method :http_url?

  private

  def contains_inline_image?(string)
    return false if string.blank?

    string.include?(inline_image_url_prefix)
  end

  def replaced_inline_images
    body_html = Nokogiri::HTML(mapped[:body])

    body_html.css('img').each do |node|
      next if !contains_inline_image?(node['src'])

      node.attributes['src'].value = self.class.inline_data(node['src'], log_context: mapped.slice(:ticket_id, :message_id))
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
