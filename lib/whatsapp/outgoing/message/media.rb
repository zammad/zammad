# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Outgoing::Message::Media < Whatsapp::Outgoing::Message
  SUPPORTED_MEDIA_TYPES = {
    audio:    WhatsappSdk::Resource::MediaTypes::AUDIO_TYPES,
    document: WhatsappSdk::Resource::MediaTypes::DOCUMENT_TYPES,
    image:    WhatsappSdk::Resource::MediaTypes::IMAGE_TYPES,
    sticker:  WhatsappSdk::Resource::MediaTypes::STICKER_TYPES,
    video:    WhatsappSdk::Resource::MediaTypes::VIDEO_TYPES,
  }.freeze

  attr_reader :medias_api

  def initialize(access_token:, phone_number_id:, recipient_number:)
    super

    @medias_api = WhatsappSdk::Api::Medias.new client
  end

  def supported_media_type?(mime_type:)
    detect_media_type(mime_type:).present?
  rescue ArgumentError
    false
  end

  def deliver(store:, caption: nil)
    mime_type = store.preferences['Mime-Type'] || store.preferences['Content-Type'] || 'application/octet-stream'
    media_type = detect_media_type(mime_type:)

    media_id = upload(store:, mime_type:)
    response = send(:"deliver_#{media_type}", media_id:, caption:)

    handle_response(response:)
  rescue WhatsappSdk::Api::Responses::HttpResponseError => e
    handle_error(response: e)
  end

  private

  def detect_media_type(mime_type:)
    media_type = SUPPORTED_MEDIA_TYPES.find { |_, mime_types| mime_types.include?(mime_type) }
    raise ArgumentError, "Unsupported media type: #{mime_type}" if !media_type

    media_type.first
  end

  def upload(store:, mime_type:)
    with_tmpfile(prefix: 'whatsapp-media-upload') do |file|
      File.binwrite(file.path, store.content)

      response = medias_api.upload(sender_id: phone_number_id.to_i, file_path: file.path, type: mime_type)

      response.id
    end
  rescue WhatsappSdk::Api::Responses::HttpResponseError => e
    handle_error(response: e)
  end

  def deliver_audio(media_id:, caption:)
    messages_api.send_audio(sender_id: phone_number_id.to_i, recipient_number: recipient_number.to_i, audio_id: media_id.to_s)
  end

  def deliver_document(media_id:, caption:)
    messages_api.send_document(sender_id: phone_number_id.to_i, recipient_number: recipient_number.to_i, document_id: media_id.to_s, caption:)
  end

  def deliver_image(media_id:, caption:)
    messages_api.send_image(sender_id: phone_number_id.to_i, recipient_number: recipient_number.to_i, image_id: media_id.to_s, caption:)
  end

  def deliver_sticker(media_id:, caption:)
    messages_api.send_sticker(sender_id: phone_number_id.to_i, recipient_number: recipient_number.to_i, sticker_id: media_id.to_s)
  end

  def deliver_video(media_id:, caption:)
    messages_api.send_video(sender_id: phone_number_id.to_i, recipient_number: recipient_number.to_i, video_id: media_id.to_s, caption:)
  end

end
