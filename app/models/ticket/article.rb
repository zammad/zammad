# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket::Article < ApplicationModel
  include HasDefaultModelUserRelations

  include CanBeImported
  include HasActivityStreamLog
  include ChecksClientNotification
  include HasHistory
  include ChecksHtmlSanitized
  include CanCsvImport
  include CanCloneAttachments
  include HasObjectManagerAttributes

  include Ticket::Article::Assets
  include Ticket::Article::EnqueueCommunicateEmailJob
  include Ticket::Article::EnqueueCommunicateFacebookJob
  include Ticket::Article::EnqueueCommunicateSmsJob
  include Ticket::Article::EnqueueCommunicateTelegramJob
  include Ticket::Article::EnqueueCommunicateTwitterJob
  include Ticket::Article::EnqueueCommunicateWhatsappJob
  include Ticket::Article::HasTicketContactAttributesImpact
  include Ticket::Article::ResetsTicketState
  include Ticket::Article::TriggersSubscriptions

  # AddsMetadataGeneral depends on AddsMetadataOriginById, so load that first
  include Ticket::Article::AddsMetadataOriginById
  include Ticket::Article::AddsMetadataGeneral
  include Ticket::Article::AddsMetadataEmail
  include Ticket::Article::AddsMetadataWhatsapp

  include HasTransactionDispatcher

  belongs_to :ticket, optional: true
  has_one    :ticket_time_accounting, class_name: 'Ticket::TimeAccounting', foreign_key: :ticket_article_id, dependent: :destroy, inverse_of: :ticket_article
  belongs_to :type,       class_name: 'Ticket::Article::Type', optional: true
  belongs_to :sender,     class_name: 'Ticket::Article::Sender', optional: true
  belongs_to :origin_by,  class_name: 'User', optional: true

  before_validation :detect_language, on: :create
  before_validation :check_mentions, on: :create
  before_validation :check_email_recipient_validity, if: :check_email_recipient_raises_error
  before_create :check_subject, :check_body, :check_message_id_md5
  before_update :check_subject, :check_body, :check_message_id_md5
  after_destroy :store_delete, :update_time_units
  after_commit :ticket_touch, if: :persisted?

  store :preferences

  validates :ticket_id, presence: true
  validates :type_id, presence: true
  validates :sender_id, presence: true

  validates_with Validations::TicketArticleValidator

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

  attr_accessor :should_clone_inline_attachments, :check_mentions_raises_error, :check_email_recipient_raises_error

  alias should_clone_inline_attachments? should_clone_inline_attachments

  # fillup md5 of message id to search easier on very long message ids
  def check_message_id_md5
    return true if message_id.blank?

    self.message_id_md5 = Digest::MD5.hexdigest(message_id.to_s)
  end

  def detect_language
    return if Setting.get('language_detection_article').blank?

    self.detected_language = LanguageDetectionHelper.detect(body.html2text)
  end

=begin

insert inline image urls to body

  article_attributes = Ticket::Article.insert_urls(article_attributes)

returns

  article_attributes_with_body_and_urls

=end

  def self.insert_urls(article)
    return article if article['attachments'].blank?
    return article if !article['content_type'].match?(%r{text/html}i)
    return article if article['body'] !~ %r{<img}i

    inline_attachments = {}
    article['body'].gsub!(%r{(<img[[:space:]](|.+?)src=")cid:(.+?)"(|.+?)>}im) do |item|
      tag_start = $1
      cid = $3
      tag_end = $4
      replace = item

      # look for attachment
      article['attachments'].each do |file|
        next if !file[:preferences] || !file[:preferences]['Content-ID'] || (file[:preferences]['Content-ID'] != cid && file[:preferences]['Content-ID'] != "<#{cid}>")

        replace = "#{tag_start}/api/v1/ticket_attachment/#{article['ticket_id']}/#{article['id']}/#{file[:id]}?view=inline\"#{tag_end}>"
        inline_attachments[file[:id]] = true
        break
      end
      replace
    end
    new_attachments = []
    article['attachments'].each do |file|
      next if inline_attachments[file[:id]]

      new_attachments.push file
    end
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
    body.gsub(%r{<img[[:space:]](|.+?)src="cid:(.+?)"(|.+?)>}im) do |_item|
      cid = $2

      # look for attachment
      attachments.each do |file|
        content_id = file.preferences['Content-ID'] || file.preferences['content_id']
        next if content_id.blank? || (content_id != cid && content_id != "<#{cid}>")

        inline_attachments[file.id] = true
        break
      end
    end
    new_attachments = []
    attachments.each do |file|
      next if !inline_attachments[file.id]

      new_attachments.push file
    end
    new_attachments
  end

  def self.last_customer_agent_article(ticket_id)
    sender = Ticket::Article::Sender.lookup(name: 'System')
    Ticket::Article.where('ticket_id = ? AND sender_id NOT IN (?)', ticket_id, sender.id).reorder(created_at: :desc).first
  end

=begin

The originator (origin_by, if any) or the creator of an article.

=end

  def author
    origin_by || created_by
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
    return body if content_type.blank? || content_type =~ %r{text/plain}i

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
      o_id:   id,
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
    Store.create!(
      object:        'Ticket::Article::Mail',
      o_id:          id,
      data:          msg,
      filename:      "ticket-#{ticket.number}-#{id}.eml",
      preferences:   {},
      created_by_id: created_by_id,
    )
  end

  def sanitizeable?(attribute, _value)
    return true if attribute != :body
    return false if content_type.blank?

    content_type =~ %r{html}i
  end

=begin

get relation name of model based on params

  model = Model.find(1)
  attributes = model.attributes_with_association_names

returns

  hash with attributes, association ids, association names and relation name

=end

  def attributes_with_association_names(empty_keys: false)
    attributes = super
    add_attachments_to_attributes(attributes)
    add_time_unit_to_attributes(attributes)
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
    add_attachments_to_attributes(attributes)
    if attributes['body'] && attributes['content_type'] =~ %r{text/html}i
      attributes['body'] = Rails.cache.fetch("#{self.class}/#{cache_key_with_version}/body/dynamic_image_size") do
        HtmlSanitizer.dynamic_image_size(attributes['body'])
      end
    end
    Ticket::Article.insert_urls(attributes)
  end

  private

  def add_attachments_to_attributes(attributes)
    attributes['attachments'] = attachments.map(&:attributes_for_display)
    attributes
  end

  def add_time_unit_to_attributes(attributes)
    attributes['time_unit'] = ticket_time_accounting&.time_unit.presence || nil
    attributes
  end

  # strip not wanted chars
  def check_subject
    return true if subject.blank?

    subject.gsub!(%r{\s|\t|\r}, ' ')
    true
  end

  # strip body length or raise exception
  def check_body
    return true if body.blank?

    limit = 1_500_000
    current_length = body.length
    return true if body.length <= limit

    raise Exceptions::UnprocessableEntity, "body of article is too large, #{current_length} chars - only #{limit} allowed" if !ApplicationHandleInfo.postmaster? && !Setting.get('import_mode')

    logger.warn "WARNING: cut string because of database length #{self.class}.body(#{limit} but is #{current_length}) - ticket_id(#{ticket_id})"
    self.body = body[0, limit]
  end

  def check_mentions
    begin
      mention_user_ids = Nokogiri::HTML(body).css('a[data-mention-user-id]').pluck('data-mention-user-id')
    rescue => e
      Rails.logger.error "Can't parse body '#{body}' as HTML for extracting Mentions."
      Rails.logger.error e
      return
    end

    return if mention_user_ids.blank?

    begin
      Pundit.authorize updated_by, ticket, :create_mentions?
    rescue Pundit::NotAuthorizedError => e
      return if ApplicationHandleInfo.postmaster?
      return if updated_by.id == 1
      return if !check_mentions_raises_error

      raise e
    end

    mention_user_ids.each do |user_id|
      begin
        Mention.subscribe! ticket, User.find(user_id)
      rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
        next if ApplicationHandleInfo.postmaster?
        next if updated_by.id == 1
        next if !check_mentions_raises_error

        raise e
      end
    end
  end

  def check_email_recipient_validity
    return if Setting.get('import_mode')

    # Check if article type is email
    email_article_type = Ticket::Article::Type.lookup(name: 'email')
    return if type_id != email_article_type.id

    # ... and if recipients are valid.
    recipients = begin
      Mail::AddressList.new(to).addresses
    rescue Mail::Field::ParseError
      nil
    end

    return if recipients.present? && recipients.all? { |recipient| EmailAddressValidation.new(recipient.address).valid? }

    raise Exceptions::InvalidAttribute.new('email_recipient', __('Sending an email without a valid recipient is not possible.'))
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

  # delete attachments and mails of article
  def store_delete
    Store.remove(
      object: 'Ticket::Article',
      o_id:   id,
    )
    Store.remove(
      object: 'Ticket::Article::Mail',
      o_id:   id,
    )
  end

  # recalculate time accounting
  def update_time_units
    Ticket::TimeAccounting.update_ticket(ticket)
  end

  def ticket_touch
    ticket.touch # rubocop:disable Rails/SkipsModelValidations
  end
end
