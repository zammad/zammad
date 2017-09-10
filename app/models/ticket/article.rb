# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class Ticket::Article < ApplicationModel
  include HasActivityStreamLog
  include ChecksClientNotification
  include HasHistory
  include ChecksHtmlSanitized
  include Ticket::Article::ChecksAccess

  load 'ticket/article/assets.rb'
  include Ticket::Article::Assets

  belongs_to    :ticket
  has_one       :ticket_time_accounting, class_name: 'Ticket::TimeAccounting', foreign_key: :ticket_article_id, dependent: :destroy
  belongs_to    :type,        class_name: 'Ticket::Article::Type'
  belongs_to    :sender,      class_name: 'Ticket::Article::Sender'
  belongs_to    :created_by,  class_name: 'User'
  belongs_to    :updated_by,  class_name: 'User'
  store         :preferences
  before_create :check_subject, :check_body, :check_message_id_md5
  before_update :check_subject, :check_body, :check_message_id_md5

  sanitized_html :body

  activity_stream_permission 'ticket.agent'

  activity_stream_attributes_ignored :type_id,
                                     :sender_id,
                                     :preferences

  history_attributes_ignored :type_id,
                             :sender_id,
                             :preferences,
                             :message_id,
                             :from,
                             :to,
                             :cc

  # fillup md5 of message id to search easier on very long message ids
  def check_message_id_md5
    return true if message_id.blank?
    self.message_id_md5 = Digest::MD5.hexdigest(message_id.to_s)
  end

=begin

insert inline image urls to body

  article_attributes = Ticket::Article.insert_urls(article_attributes)

returns

  article_attributes_with_body_and_urls

=end

  def self.insert_urls(article)
    return article if article['attachments'].blank?
    return article if article['content_type'] !~ %r{text/html}i
    return article if article['body'] !~ /<img/i

    inline_attachments = {}
    article['body'].gsub!( /(<img[[:space:]](|.+?)src=")cid:(.+?)"(|.+?)>/im ) { |item|
      tag_start = $1
      cid = $3
      tag_end = $4
      replace = item

      # look for attachment
      article['attachments'].each { |file|
        next if !file[:preferences] || !file[:preferences]['Content-ID'] || (file[:preferences]['Content-ID'] != cid && file[:preferences]['Content-ID'] != "<#{cid}>" )
        replace = "#{tag_start}/api/v1/ticket_attachment/#{article['ticket_id']}/#{article['id']}/#{file[:id]}\"#{tag_end}>"
        inline_attachments[file[:id]] = true
        break
      }
      replace
    }
    new_attachments = []
    article['attachments'].each { |file|
      next if inline_attachments[file[:id]]
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
    body.gsub( /<img[[:space:]](|.+?)src="cid:(.+?)"(|.+?)>/im ) { |_item|
      cid = $2

      # look for attachment
      attachments.each { |file|
        next if !file.preferences['Content-ID'] || (file.preferences['Content-ID'] != cid && file.preferences['Content-ID'] != "<#{cid}>" )
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

=begin

get article as raw (e. g. if it's a email, the raw email)

  article = Ticket::Article.find(123)
  article.as_raw

returns:

  file # Store

=end

  def as_raw
    list = Store.list(
      object: 'Ticket::Article::Mail',
      o_id: id,
    )
    return if list.blank?
    list[0]
  end

=begin

save article as raw (e. g. if it's a email, the raw email)

  article = Ticket::Article.find(123)
  article.save_as_raw(msg)

returns:

  file # Store

=end

  def save_as_raw(msg)
    Store.add(
      object: 'Ticket::Article::Mail',
      o_id: id,
      data: msg,
      filename: "ticket-#{ticket.number}-#{id}.eml",
      preferences: {},
      created_by_id: created_by_id,
    )
  end

  def sanitizeable?(attribute, _value)
    return true if attribute != :body
    return false if content_type.blank?
    content_type =~ /html/i
  end

=begin

get relation name of model based on params

  model = Model.find(1)
  attributes = model.attributes_with_association_names

returns

  hash with attributes, association ids, association names and relation name

=end

  def attributes_with_association_names
    attributes = super
    attributes['attachments'] = []
    attachments.each { |attachment|
      item = {
        id: attachment['id'],
        filename: attachment['filename'],
        size: attachment['size'],
        preferences: attachment['preferences'],
      }
      attributes['attachments'].push item
    }
    Ticket::Article.insert_urls(attributes)
  end

=begin

get relations of model based on params

  model = Model.find(1)
  attributes = model.attributes_with_association_ids

returns

  hash with attributes and association ids

=end

  def attributes_with_association_ids
    attributes = super
    attributes['attachments'] = []
    attachments.each { |attachment|
      item = {
        id: attachment['id'],
        filename: attachment['filename'],
        size: attachment['size'],
        preferences: attachment['preferences'],
      }
      attributes['attachments'].push item
    }
    if attributes['body'] && attributes['content_type'] =~ %r{text/html}i
      attributes['body'] = HtmlSanitizer.dynamic_image_size(attributes['body'])
    end
    Ticket::Article.insert_urls(attributes)
  end

  private

  # strip not wanted chars
  def check_subject
    return true if subject.blank?
    subject.gsub!(/\s|\t|\r/, ' ')
    true
  end

  # strip body length or raise exception
  def check_body
    return true if body.blank?
    limit = 1_500_000
    current_length = body.length
    if body.length > limit
      if ApplicationHandleInfo.current.present? && ApplicationHandleInfo.current.split('.')[1] == 'postmaster'
        logger.warn "WARNING: cut string because of database length #{self.class}.body(#{limit} but is #{current_length})"
        self.body = body[0, limit]
      else
        raise Exceptions::UnprocessableEntity, "body if article is to large, #{current_length} chars - only #{limit} allowed"
      end
    end
    true
  end

  def history_log_attributes
    {
      related_o_id:           self['ticket_id'],
      related_history_object: 'Ticket',
    }
  end

  # callback function to overwrite
  # default history stream log attributes
  # gets called from activity_stream_log
  def activity_stream_log_attributes
    {
      group_id: Ticket.find(ticket_id).group_id,
    }
  end

  class Flag < ApplicationModel
  end

  class Sender < ApplicationModel
    include ChecksLatestChangeObserved
    validates :name, presence: true
  end

  class Type < ApplicationModel
    include ChecksLatestChangeObserved
    validates :name, presence: true
  end
end
