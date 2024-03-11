# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Whatsapp

  MIME_TYPES = {
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
  }.freeze

  def self.file_suffix(mime_type:)
    identified_mime_type = Whatsapp::MIME_TYPES[mime_type.to_sym]
    return identified_mime_type if identified_mime_type.present?

    identified_mime_type = MIME::Types[mime_type]&.first
    return identified_mime_type.preferred_extension if identified_mime_type.present? && identified_mime_type.preferred_extension.present?

    'dat'
  end
end
