# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::AppliesTicketSharedDraft
  extend ActiveSupport::Concern

  def resolve
    if agent? && selected_draft.present?
      apply_draft
    end

    super
  end

  private

  def apply_draft
    apply_value = FormUpdater::ApplyValue.new(context:, data:, meta:, result:)

    new_attachments = UserInfo.with_user_id(context[:current_user].id) do
      selected_draft.clone_attachments('UploadCache', meta[:form_id])
    end

    apply_value.perform(field: 'attachments', config: { 'value' => new_attachments.reject(&:inline?) })

    selected_draft
      .content_with_form_id_body_urls(meta[:form_id])
      .each_pair do |field, value|
        apply_value.perform(field: field, config: { 'value' => value })
      end

    # Include shared draft internal ID for a subsequent reference.
    apply_value.perform(field: 'shared_draft_id', config: { 'value' => selected_draft.id })
  end

  def selected_draft
    @selected_draft ||= begin
      id = meta.dig(:additional_data, 'sharedDraftStartId')

      Gql::ZammadSchema.authorized_object_from_id(id, type: Ticket::SharedDraftStart, user: context[:current_user]) if id.present?
    end
  end

  def agent?
    current_user.permissions?('ticket.agent')
  end
end
