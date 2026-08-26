# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module CanLookupSearchIndexAttributesWithAttachments
  extend ActiveSupport::Concern

  def search_index_attachments_lookup(current_size)
    attachments.filter_map do |attachment|

      next if !search_index_attachment_indexable?(attachment, current_size)

      attachment_attributes = SearchIndexBackend.attachment_to_attributes(attachment)
      current_size += attachment_attributes['_size']

      attachment_attributes
    end
  end

  private

  def search_index_attachment_indexable?(attachment, current_size)
    return false if SearchIndexBackend.attachment_ignored?(attachment)
    return false if SearchIndexBackend.attachment_too_big?(attachment)
    return false if SearchIndexBackend.payload_too_big?(current_size + attachment.content.bytesize)

    true
  end
end
