# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Remove PDF from the allowed inline content types so they have to be downloaded first (#4479).
Rails.application.config.active_storage.content_types_allowed_inline.delete('application/pdf')

# Add legacy/invalid content type image/jpg (rather than image/jpeg) to allow showing of legacy avatars.
Rails.application.config.active_storage.content_types_allowed_inline.push('image/jpg')

# Serve JavaScript attachments as binary, so they are downloaded rather than interpreted.
#   Covers the full list of JavaScript MIME types from the HTML specification
#   (https://html.spec.whatwg.org/multipage/scripting.html#javascript-mime-type),
#   since a browser executes a script response labeled with any of them.
Rails.application.config.active_storage.content_types_to_serve_as_binary.push(
  'application/ecmascript',
  'application/javascript',
  'application/x-ecmascript',
  'application/x-javascript',
  'text/ecmascript',
  'text/javascript',
  'text/javascript1.0',
  'text/javascript1.1',
  'text/javascript1.2',
  'text/javascript1.3',
  'text/javascript1.4',
  'text/javascript1.5',
  'text/jscript',
  'text/livescript',
  'text/x-ecmascript',
  'text/x-javascript',
)
