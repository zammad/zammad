# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Ticket::SharedDraftZoom < ApplicationModel
  include HasRichText
  include HasDefaultModelUserRelations

  include CanCloneAttachments
  include ChecksClientNotification
  include HasHistory

  belongs_to :ticket, touch: true

  store :new_article
  store :ticket_attributes

  history_attributes_ignored :new_article,
                             :ticket_attributes

  # required by CanCloneAttachments
  def content_type
    'text/html'
  end

  # Process inline images
  has_rich_text :body

  # has_rich_text cannot process data inside hashes
  # Using a meta attribute instead
  def body
    new_article[:body]
  end

  # has_rich_text cannot process data inside hashes
  # Using a meta attribute instead
  def body=(input)
    new_article[:body] = input
  end

  # Adds backwards compatibility for the old desktop app
  def body_with_base64
    scrubber = HtmlSanitizer::Scrubber::InsertInlineImages.new(attachments)

    sanitized = Loofah
      .fragment(body)
      .scrub!(scrubber)

    sanitized.to_s
  end

  # Returns images with src=/api/v1/attachments/1337
  def content_with_body_urls
    # TODO: new_article + ticket_attributes must be put together.
    output = new_article.deep_dup
    output[:body] = body_with_urls

    output
  end

  # Returns content prepared to be applied to the ticket
  #
  # @param form_id [String] id of the form to attach to
  def content_with_form_id_body_urls(form_id)
    cache = UploadCache.new(form_id)

    article = new_article.deep_dup
    article[:body] = HasRichText.insert_urls(article[:body], cache.attachments)

    {
      article: article,
      ticket:  ticket_attributes,
    }
  end

  def history_log_attributes
    {
      related_o_id:           self['ticket_id'],
      related_history_object: 'Ticket',
    }
  end

  def history_destroy
    history_log('removed', created_by_id)
  end

  def attributes_with_association_ids
    attrs = super

    attrs.delete 'body'
    attrs['new_article']['body'] = body_with_base64 if attrs.dig('new_article', 'body').present?

    attrs
  end
end
