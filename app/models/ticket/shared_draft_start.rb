# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Ticket::SharedDraftStart < ApplicationModel
  include HasRichText
  include HasDefaultModelUserRelations

  include CanCloneAttachments
  include ChecksClientNotification

  belongs_to :group

  validates :name, presence: true

  before_validation :clear_group_id
  after_commit :trigger_subscriptions

  store :content

  # don't include content into assets which may be huge
  # assets are used to load the whole list of available drafts
  # content is loaded separately
  def filter_attributes(attributes)
    super.except! 'content'
  end

  # required by CanCloneAttachments
  def content_type
    'text/html'
  end

  # Process inline images
  has_rich_text :body

  # has_rich_text cannot process data inside hashes
  # Using a meta attribute instead
  def body
    content[:body]
  end

  # has_rich_text cannot process data inside hashes
  # Using a meta attribute instead
  def body=(input)
    content[:body] = input
  end

  # Adds backwards compatibility for the old desktop app
  def body_with_base64
    scrubber = HtmlSanitizer::Scrubber::InsertInlineImages.new(attachments)

    sanitized = Loofah
      .fragment(body)
      .scrub!(scrubber)

    sanitized.to_s
  end

  # Adds backwards compatibility for the old desktop app
  def content_with_base64
    output = content.deep_dup
    output[:body] = body_with_base64

    output
  end

  # Returns images with src=/api/v1/attachments/1337
  def content_with_body_urls
    output = content.deep_dup
    output[:body] = body_with_urls

    output
  end

  # Returns content prepared to be applied to the ticket
  #
  # @param form_id [String] id of the form to attach to
  def content_with_form_id_body_urls(form_id)
    cache = UploadCache.new(form_id)

    output = content.deep_dup
    output[:body] = HasRichText.insert_urls(output[:body], cache.attachments)

    output
  end

  private

  def clear_group_id
    content.delete :group_id
  end

  def trigger_subscriptions
    [group_id, group_id_previously_was]
      .compact
      .uniq
      .each do |elem|
        Gql::Subscriptions::Ticket::SharedDraft::Start::UpdateByGroup
          .trigger(nil, arguments: { group_id: Gql::ZammadSchema.id_from_internal_id('Group', elem) })
      end
  end
end
