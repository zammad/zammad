# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message::Media < Whatsapp::Webhook::Message
  private

  def attachment?
    true
  end

  def body
    message[:caption].present? ? "<p>#{message[:caption]}</p>" : ''
  end

  def content_type
    'text/html'
  end

  def attachment
    media = Whatsapp::Incoming::Media.new(access_token: @channel.options[:access_token])
    data, mime_type = media.download(media_id: message[:id])
    filename = message[:filename].presence || "#{ticket.number}-#{message[:id]}.#{Whatsapp.file_suffix(mime_type:)}"

    [data, filename, mime_type]
  end

  def article_preferences
    preferences = {
      media_id: message[:id],
    }

    if message[:filename].present?
      preferences[:filename] = message[:filename]
    end

    super().merge(preferences)
  end
end
