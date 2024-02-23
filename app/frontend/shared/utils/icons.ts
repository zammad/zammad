// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export const getIconByContentType = (type?: Maybe<string>) => {
  if (!type) return 'file'
  const contentType = type.replace(/^(.+?\/.+?)(\b|\s).+?$/, '$1')

  const icons: Record<string, string> = {
    // image
    'image/jpeg': 'photos',
    'image/jpg': 'photos',
    'image/png': 'photos',
    'image/svg': 'photos',
    'image/gif': 'photos',
    'image/webp': 'photos',
    // audio
    'audio/aac': 'audio',
    'audio/mp4': 'audio',
    'audio/mpeg': 'audio',
    'audio/amr': 'audio',
    'audio/ogg': 'audio',
    // video
    'video/mp4': 'video',
    'video/3gp': 'video',
    // documents
    'application/pdf': 'library',
    'application/msword': 'template', // .doc, .dot
    'application/vnd.ms-word': 'template',
    'application/vnd.oasis.opendocument.text': 'template',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
      'template', // .docx
    'application/vnd.openxmlformats-officedocument.wordprocessingml.template':
      'template', // .dotx
    'application/vnd.ms-excel': 'file', // .xls
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'file', // .xlsx
    'application/vnd.oasis.opendocument.spreadsheet': 'file',
    'application/vnd.ms-powerpoint': 'file', // .ppt
    'application/vnd.openxmlformats-officedocument.presentationml.presentation':
      'file', // .pptx
    'application/vnd.oasis.opendocument.presentation': 'file',
    // code
    'text/html': 'template',
    'application/json': 'template',
    'message/rfc822': 'mail-out',
    // text
    'text/plain': 'template',
    'text/rtf': 'template',
    'text/calendar': 'calendar',
    // archives
    'application/gzip': 'attachment',
    'application/zip': 'attachment',
  }
  return icons[contentType] || 'file'
}
