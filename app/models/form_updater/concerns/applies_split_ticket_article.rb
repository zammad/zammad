# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::AppliesSplitTicketArticle
  extend ActiveSupport::Concern

  def resolve
    if agent? && selected_ticket_article.present?
      apply_ticket_article
    end

    super
  end

  private

  def apply_value
    @apply_value ||= FormUpdater::ApplyValue.new(context:, data:, result:)
  end

  def apply_ticket_article
    apply_attachments
    apply_link_ticket_id

    attributes_to_apply.each do |key, value|
      apply_value.perform(
        field:  key,
        config: { 'value' => value }
      )
    end
  end

  def apply_attachments
    new_attachments = UserInfo.with_user_id(context[:current_user].id) do
      selected_ticket_article.clone_attachments('UploadCache', meta[:form_id])
    end

    apply_value.perform(field: 'attachments', config: { 'value' => new_attachments.reject(&:inline?) })
  end

  def attributes_to_apply
    attrs = selected_ticket_article.ticket.attributes

    attrs['title'] = selected_ticket_article.subject if selected_ticket_article.subject.present?
    attrs['body']  = body_with_form_id_urls
    attrs.delete 'owner_id'

    attrs
  end

  def body_with_form_id_urls
    cache = UploadCache.new(meta[:form_id])

    HasRichText.insert_urls(selected_ticket_article.body_as_html, cache.attachments)
  end

  def apply_link_ticket_id
    apply_value.perform(
      field:  'link_ticket_id',
      config: { 'value' => selected_ticket_article.ticket.id }
    )
  end

  def selected_ticket_article
    @selected_ticket_article ||= begin
      gid = meta.dig(:additional_data, 'splitTicketArticleId')

      Gql::ZammadSchema.authorized_object_from_id(gid, type: Ticket::Article, user: context[:current_user]) if gid.present?
    end
  end

  def agent?
    current_user.permissions?('ticket.agent')
  end
end
