# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Remove PDF from the allowed inline content types so they have to be downloaded first (#4479).
Rails.application.config.active_storage.content_types_allowed_inline.delete('application/pdf')

# Add legacy/invalid content type image/jpg (rather than image/jpeg) to allow showing of legacy avatars.
Rails.application.config.active_storage.content_types_allowed_inline.push('image/jpg')
