# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::HasAttachments
  extend ActiveSupport::Concern

  included do
    after_create :attachments_buffer_check
    after_update :attachments_buffer_check
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

store attachments for this object

  item = Model.find(123)
  item.attachments = [ Store-Object1, Store-Object2 ]

=end

  def attachments=(attachments)
    self.attachments_buffer = attachments

    # update if object already exists
    return if !(id&.nonzero?)

    attachments_buffer_check
  end

  private

  def attachments_buffer
    @attachments_buffer_data
  end

  def attachments_buffer=(attachments)
    @attachments_buffer_data = attachments
  end

  def attachments_buffer_check

    # do nothing if no attachment exists
    return 1 if attachments_buffer.nil?

    # store attachments
    article_store = []
    attachments_buffer.each do |attachment|
      article_store.push Store.add(
        object:        self.class.to_s,
        o_id:          id,
        data:          attachment.content,
        filename:      attachment.filename,
        preferences:   attachment.preferences,
        created_by_id: created_by_id,
      )
    end
  end
end
