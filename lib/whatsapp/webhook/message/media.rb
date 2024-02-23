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
    filename = "#{ticket.number}-#{message[:id]}.#{file_suffix(mime_type:)}"

    [data, filename, mime_type]
  end

  def article_preferences
    super().merge(
      media_id: message[:id],
    )
  end

  def file_suffix(mime_type:)
    {
      'text/plain':                                                                'txt',
      'application/pdf':                                                           'pdf',
      'application/vnd.ms-powerpoint':                                             'ppt',
      'application/msword':                                                        'doc',
      'application/vnd.ms-excel':                                                  'xls',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document':   'docx',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation': 'pptx',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':         'xlsx',

      'image/jpeg':                                                                'jpeg',
      'image/png':                                                                 'png',
      'image/webp':                                                                'webp',

      'video/mp4':                                                                 'mp4',
      'video/3gp':                                                                 '3gp',

      'audio/aac':                                                                 'aac',
      'audio/mp4':                                                                 'm4a',
      'audio/mpeg':                                                                'mp3',
      'audio/amr':                                                                 'amr',
      'audio/ogg':                                                                 'ogg',
    }[mime_type.to_sym] || 'data'
  end
end
