# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::AppliesTicketSharedDraft
  extend ActiveSupport::Concern

  class_methods do
    def apply_shared_draft_group_keys(group_keys)
      @apply_shared_draft_group_keys ||= group_keys
    end
  end

  def resolve
    if agent? && selected_draft.present?
      apply_draft
    end

    super
  end

  private

  def apply_draft
    apply_value = FormUpdater::ApplyValue.new(context:, data:, result:)

    new_attachments = UserInfo.with_user_id(context[:current_user].id) do
      selected_draft.clone_attachments('UploadCache', meta[:form_id])
    end

    apply_value.perform(field: 'attachments', config: { 'value' => new_attachments.reject(&:inline?) })

    apply_shared_draft_group_keys = self.class.instance_variable_get(:@apply_shared_draft_group_keys)

    selected_draft
      .content_with_form_id_body_urls(meta[:form_id])
      .each_pair do |field, value|
        if apply_shared_draft_group_keys.present? && apply_shared_draft_group_keys.include?(field) && value.is_a?(Hash)
          value.each_pair do |sub_field, sub_value|
            apply_value.perform(field: sub_field, config: { 'value' => sub_value }, parent_field: field)
          end
        else
          apply_value.perform(field: field, config: { 'value' => value })
        end
      end

    # Include shared draft internal ID for a subsequent reference.
    apply_value.perform(field: 'shared_draft_id', config: { 'value' => selected_draft.id })
  end

  def selected_draft
    @selected_draft ||= begin
      id         = meta.dig(:additional_data, 'sharedDraftId')
      draft_type = meta.dig(:additional_data, 'draftType') == 'start' ? ::Ticket::SharedDraftStart : ::Ticket::SharedDraftZoom

      Gql::ZammadSchema.authorized_object_from_id(id, type: draft_type, user: context[:current_user]) if id.present?
    end
  end

  def agent?
    current_user.permissions?('ticket.agent')
  end
end
