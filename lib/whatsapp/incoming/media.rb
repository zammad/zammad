# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Incoming::Media < Whatsapp::Client

  attr_reader :medias_api

  def initialize(access_token:)
    super

    @medias_api = WhatsappSdk::Api::Medias.new client
  end

  def download(media_id:)
    metadata = retrieve_metadata(media_id:)

    content = retrieve_content(url: metadata[:url], media_type: metadata[:media_type])

    raise InvalidChecksumError if !valid_checksum?(content, metadata[:sha256])

    [content, metadata[:media_type]]
  rescue WhatsappSdk::Api::Medias::InvalidMediaTypeError => e
    raise InvalidMediaTypeError, e.message
  end

  private

  def retrieve_metadata(media_id:)
    response = medias_api.media(media_id:)

    handle_error(response:)

    {
      url:        response.data.url,
      media_type: response.data.mime_type,
      sha256:     response.data.sha256,
    }
  end

  def retrieve_content(url:, media_type:)
    with_tmpfile(prefix: 'whatsapp-media-download') do |file|
      response = medias_api.download(url:, file_path: file.path, media_type:)

      handle_error(response:)

      file.read
    end
  end

  def valid_checksum?(content, sha256)
    Digest::SHA2.new(256).hexdigest(content) == sha256
  end

  class InvalidChecksumError < StandardError
    def initialize
      super(__('Integrity verification of the downloaded WhatsApp media failed.'))
    end
  end

  class InvalidMediaTypeError < StandardError; end
end
