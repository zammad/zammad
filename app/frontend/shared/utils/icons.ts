// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export const getIconByContentType = (type?: Maybe<string>) => {
  if (!type) return 'mobile-file'
  const contentType = type.replace(/^(.+?\/.+?)(\b|\s).+?$/, '$1')

  const icons: Record<string, string> = {
    //   #image
    'image/jpeg': 'mobile-photos',
    'image/jpg': 'mobile-photos',
    'image/png': 'mobile-photos',
    'image/svg': 'mobile-photos',
    'image/gif': 'mobile-photos',
    //   # documents
    'application/pdf': 'mobile-library',
    'application/msword': 'mobile-template', // .doc, .dot
    'application/vnd.ms-word': 'mobile-template',
    'application/vnd.oasis.opendocument.text': 'mobile-template',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
      'mobile-template', // .docx
    'application/vnd.openxmlformats-officedocument.wordprocessingml.template':
      'mobile-template', // .dotx
    'application/vnd.ms-excel': 'mobile-file', // .xls
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
      'mobile-file', // .xlsx
    'application/vnd.oasis.opendocument.spreadsheet': 'mobile-file',
    'application/vnd.ms-powerpoint': 'mobile-file', // .ppt
    'application/vnd.openxmlformats-officedocument.presentationml.presentation':
      'mobile-file', // .pptx
    'application/vnd.oasis.opendocument.presentation': 'mobile-file',
    'text/plain': 'mobile-template',
    'text/html': 'mobile-template',
    'application/json': 'mobile-template',
    'message/rfc822': 'mobile-mail-out',
    'text/rtf': 'mobile-template',
    'text/calendar': 'mobile-calendar',
    //   # archives
    'application/gzip': 'mobile-attachment',
    'application/zip': 'mobile-attachment',
  }
  return icons[contentType] || 'mobile-file'
}
