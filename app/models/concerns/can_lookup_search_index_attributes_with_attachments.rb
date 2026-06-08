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
    if SearchIndexBackend.attachment_ignored?(attachment)
      search_index_attachment_log "Attachment #{attachment.id} is ignored for search index due to its file name or type."
      return false
    end

    if SearchIndexBackend.attachment_too_big?(attachment)
      search_index_attachment_log "Attachment #{attachment.id} is ignored for search index due to its file size."
      return false
    end

    if SearchIndexBackend.payload_too_big?(current_size + attachment.content.bytesize)
      search_index_attachment_log "Attachment #{attachment.id} is ignored for search index due to total payload size limit."
      return false
    end

    true
  end

  def search_index_attachment_log(message)
    Rails.logger.info message

    return if !defined?(Rack) || !defined?(Rack.application) || Rack.application.top_level_tasks.none?

    puts message # rubocop:disable Rails/Output
  end
end
