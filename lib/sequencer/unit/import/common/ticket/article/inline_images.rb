# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Ticket::Article::InlineImages < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :mapped

  def process
    return if !contains_inline_image?(mapped[:body])

    provide_mapped do
      {
        body: replaced_inline_images,
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

  def inline_image_url_prefix
    raise NotImplementedError
  end
end
