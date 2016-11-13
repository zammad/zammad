# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class Ticket::Article < ApplicationModel
  load 'ticket/article/assets.rb'
  include Ticket::Article::Assets
  load 'ticket/article/history_log.rb'
  include Ticket::Article::HistoryLog
  load 'ticket/article/activity_stream_log.rb'
  include Ticket::Article::ActivityStreamLog

  belongs_to    :ticket
  belongs_to    :type,        class_name: 'Ticket::Article::Type'
  belongs_to    :sender,      class_name: 'Ticket::Article::Sender'
  belongs_to    :created_by,  class_name: 'User'
  belongs_to    :updated_by,  class_name: 'User'
  store         :preferences
  before_create :check_subject, :check_message_id_md5
  before_update :check_subject, :check_message_id_md5

  notify_clients_support

  activity_stream_support(
    permission: 'ticket.agent',
    ignore_attributes: {
      type_id: true,
      sender_id: true,
      preferences: true,
    }
  )

  history_support(
    ignore_attributes: {
      type_id: true,
      sender_id: true,
      preferences: true,
      message_id: true,
      from: true,
      to: true,
      cc: true,
    }
  )

  # fillup md5 of message id to search easier on very long message ids
  def check_message_id_md5
    return if !message_id
    return if message_id_md5
    self.message_id_md5 = Digest::MD5.hexdigest(message_id.to_s)
  end

=begin

insert inline image urls to body

  article_attributes = Ticket::Article.insert_urls(
    article_attributes,
    attachments,
  )

returns

  article_attributes_with_body_and_urls

=end

  def self.insert_urls(article, attachments)
    inline_attachments = {}
    article['body'].gsub!( /(<img[[:space:]](.+?|)src=")cid:(.+?)(">)/i ) { |item|
      replace = item

      # look for attachment
      attachments.each { |file|
        next if !file.preferences['Content-ID'] || file.preferences['Content-ID'] != $3
        replace = "#{$1}/api/v1/ticket_attachment/#{article['ticket_id']}/#{article['id']}/#{file.id}#{$4}"
        inline_attachments[file.id] = true
        break
      }
      replace
    }
    new_attachments = []
    attachments.each { |file|
      next if inline_attachments[file.id]
      new_attachments.push file
    }
    article['attachments'] = new_attachments
    article
  end

=begin

get inline attachments of article

  article = Ticket::Article.find(123)
  attachments = article.attachments_inline

returns

  [attachment1, attachment2, ...]

=end

  def attachments_inline
    inline_attachments = {}
    body.gsub( /<img[[:space:]](.+?|)src="cid:(.+?)">/i ) { |_item|

      # look for attachment
      attachments.each { |file|
        next if !file.preferences['Content-ID'] || file.preferences['Content-ID'] != $2
        inline_attachments[file.id] = true
        break
      }
    }
    new_attachments = []
    attachments.each { |file|
      next if !inline_attachments[file.id]
      new_attachments.push file
    }
    new_attachments
  end

  def self.last_customer_agent_article(ticket_id)
    sender = Ticket::Article::Sender.lookup(name: 'System')
    Ticket::Article.where('ticket_id = ? AND sender_id NOT IN (?)', ticket_id, sender.id).order('created_at DESC').first
  end

=begin

get body as html

  article = Ticket::Article.find(123)
  article.body_as_html

=end

  def body_as_html
    return '' if !body
    return body if content_type && content_type =~ %r{text/html}i
    body.text2html
  end

=begin

get body as text

  article = Ticket::Article.find(123)
  article.body_as_text

=end

  def body_as_text
    return '' if !body
    return body if !content_type || content_type.empty? || content_type =~ %r{text/plain}i
    body.html2text
  end

=begin

get body as text with quote sign "> " at the beginning of each line

  article = Ticket::Article.find(123)
  article.body_as_text

=end

  def body_as_text_with_quote
    body_as_text.word_wrap.message_quote
  end

  private

  # strip not wanted chars
  def check_subject
    return if !subject
    subject.gsub!(/\s|\t|\r/, ' ')
  end

  class Flag < ApplicationModel
  end

  class Sender < ApplicationModel
    validates :name, presence: true
    latest_change_support
  end

  class Type < ApplicationModel
    validates :name, presence: true
    latest_change_support
  end
end
