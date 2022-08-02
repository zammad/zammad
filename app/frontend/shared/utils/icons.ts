// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

export const getIconByContentType = (type?: Maybe<string>) => {
  if (!type) return 'file-unknown'
  const contentType = type.replace(/^(.+?\/.+?)(\b|\s).+?$/, '$1')

  const icons: Record<string, string> = {
    //   #image
    'image/jpeg': 'file-image',
    'image/jpg': 'file-image',
    'image/png': 'file-image',
    'image/svg': 'file-image',
    'image/gif': 'file-image',
    //   # documents
    'application/pdf': 'file-pdf',
    'application/msword': 'file-word', // .doc, .dot
    'application/vnd.ms-word': 'file-word',
    'application/vnd.oasis.opendocument.text': 'file-word',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
      'file-word', // .docx
    'application/vnd.openxmlformats-officedocument.wordprocessingml.template':
      'file-word', // .dotx
    'application/vnd.ms-excel': 'file-excel', // .xls
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
      'file-excel', // .xlsx
    'application/vnd.oasis.opendocument.spreadsheet': 'file-excel',
    'application/vnd.ms-powerpoint': 'file-powerpoint', // .ppt
    'application/vnd.openxmlformats-officedocument.presentationml.presentation':
      'file-powerpoint', // .pptx
    'application/vnd.oasis.opendocument.presentation': 'file-powerpoint',
    'text/plain': 'file-text',
    'text/html': 'file-code',
    'application/json': 'file-code',
    'message/rfc822': 'file-email',
    'text/rtf': 'file-text',
    'text/calendar': 'file-calendar',
    //   # archives
    'application/gzip': 'file-archive',
    'application/zip': 'file-archive',
  }
  return icons[contentType] || 'file-unknown'
}
