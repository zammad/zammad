# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Retry::Media
  attr_reader :article, :channel

  def initialize(article:)
    @article = article
    raise ArticleInvalidError if media_id.blank?

    @channel = find_channel!
  end

  def process
    download_media
    update_article
  end

  private

  def update_article
    article.preferences['whatsapp'].delete('media_error')
    article.save!
  end

  def media_id
    @media_id ||= article.preferences&.dig('whatsapp', 'media_id')
  end

  def find_channel!
    channel_id = article.ticket.preferences&.dig('channel_id')
    raise ArticleInvalidError if channel_id.nil?

    Channel.find_by(id: channel_id).tap do |channel|
      if channel.nil? || channel.area != 'WhatsApp::Business' || !channel.active
        raise ArticleInvalidError
      end
    end
  end

  def download_media
    data, filename, mime_type = attachment

    Store.create!(
      object:      'Ticket::Article',
      o_id:        article.id,
      data:        data,
      filename:    filename,
      preferences: {
        'Mime-Type' => mime_type,
      },
    )
  end

  def attachment
    media = Whatsapp::Incoming::Media.new(access_token: channel.options[:access_token])
    data, mime_type = media.download(media_id: media_id)
    filename = article.preferences.dig('whatsapp', 'filename').presence || "#{article.ticket.number}-#{media_id}.#{Whatsapp.file_suffix(mime_type:)}"

    [data, filename, mime_type]
  end

  class ArticleInvalidError < StandardError
    attr_reader :reason

    def initialize(reason = __('The given article is not a media article.'))
      @reason = reason
      message = __('Retrying to download the sent media via WhatsApp failed.')
      message += " #{reason}" if reason.present?
      super(message)
    end
  end
end
