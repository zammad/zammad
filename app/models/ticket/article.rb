class Ticket::Article < ApplicationModel
  after_create  :attachment_check
  belongs_to    :ticket
  belongs_to    :ticket_article_type,   :class_name => 'Ticket::Article::Type'
  belongs_to    :ticket_article_sender, :class_name => 'Ticket::Article::Sender'
  belongs_to    :created_by,            :class_name => 'User'

  private
    def attachment_check

      # do nothing if no attachment exists
      return 1 if self['attachments'] == nil

      # store attachments
      article_store = []
      self.attachments.each do |attachment|
        article_store.push Store.add(
          :object      => 'Ticket::Article',
          :o_id        => self.id,
          :data        => attachment.store_file.data,
          :filename    => attachment.filename,
          :preferences => attachment.preferences
        )
      end
      self.attachments = article_store
    end

  class Flag < ApplicationModel
  end

  class Sender < ApplicationModel
    validates   :name, :presence => true
  end

  class Type < ApplicationModel
    validates   :name, :presence => true
  end
end
