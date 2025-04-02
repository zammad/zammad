# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module ApplicationModel::HasAttachments
  extend ActiveSupport::Concern

  included do
    after_save    :attachments_buffer_check
    after_destroy :attachments_remove_all, if: :attachments_cleanup?

    class_attribute :attachments_cleanup, default: false
  end

  class_methods do
=begin
  mark model for cleaning up after destroying
=end

    def attachments_cleanup!
      self.attachments_cleanup = true
    end
  end

  def attachments_remove_all
    attachments.each { |attachment| Store.remove_item(attachment.id) }
  end

=begin

get list of attachments of this object

  item = Model.find(123)
  list = item.attachments

returns

  # array with Store model objects

=end

  def attachments
    Store.list(object: self.class.to_s, o_id: id)
  end

=begin

store attachments for this object with store objects or hashes

  item = Model.find(123)
  item.attachments = [
    Store-Object1,
    Store-Object2,
    {
      filename: 'test.txt',
      data: 'test',
      preferences: {},
    }
  ]

=end

  def attachments=(attachments)
    @attachments_buffer = attachments
  end

=begin

Returns attachments in ElasticSearch-compatible format
For use in #search_index_attribute_lookup

=end

  def attachments_for_search_index_attribute_lookup
    # list ignored file extensions
    attachments_ignore = Setting.get('es_attachment_ignore') || [ '.png', '.jpg', '.jpeg', '.mpeg', '.mpg', '.mov', '.bin', '.exe' ]

    # max attachment size
    attachment_max_size_in_mb = (Setting.get('es_attachment_max_size_in_mb') || 10).megabytes
    attachment_total_max_size_in_kb = 314_572.kilobytes
    attachment_total_max_size_in_kb_current = 0.kilobytes

    attachments.each_with_object([]) do |attachment, memo|
      # check if attachment exists
      next if !attachment.content

      size_in_bytes = attachment.content.size.bytes

      # check file size
      next if size_in_bytes > attachment_max_size_in_mb

      # check ignored files
      next if !attachment.filename || attachments_ignore.include?(File.extname(attachment.filename).downcase)

      # check if fits into total size limit
      next if attachment_total_max_size_in_kb_current + size_in_bytes > attachment_total_max_size_in_kb

      attachment_total_max_size_in_kb_current += size_in_bytes

      memo << {
        '_name'    => attachment.filename,
        '_content' => Base64.encode64(attachment.content).delete("\n")
      }
    end
  end

  private

  def attachments_buffer_check
    return if @attachments_buffer.blank?

    @attachments_buffer.each do |attachment|
      Store.create!(
        object:        self.class.to_s,
        o_id:          id,
        created_by_id: created_by_id,
        filename:      attachment[:filename],
        preferences:   attachment[:preferences],
        data:          attachment.try(:content) || attachment[:data]
      )
    end

    @attachments_buffer = nil
  end
end
