# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
      cloned_attachments = selected_draft.clone_attachments('UploadCache', meta[:form_id])

      remove_stale_inline_attachments

      cloned_attachments
    end

    apply_value.perform(field: 'attachments', config: { 'value' => new_attachments.reject(&:inline?) })

    apply_shared_draft_group_keys = self.class.instance_variable_get(:@apply_shared_draft_group_keys)

    selected_draft
      .content_with_form_id_body_urls(meta[:form_id])
      .each_pair do |field, value|
        if apply_shared_draft_group_keys.present? && apply_shared_draft_group_keys.include?(field) && value.is_a?(Hash)
          value.each_pair do |sub_field, sub_value|
            apply_value.perform(field: sub_field, config: { 'value' => sub_value }, parent_field: field)

            check_applied_field_from_group_key(field, sub_field)
          end
        else
          apply_value.perform(field: field, config: { 'value' => value })
        end
      end

    # Include shared draft internal ID for a subsequent reference.
    apply_value.perform(field: 'shared_draft_id', config: { 'value' => selected_draft.id })
  end

  # A draft's inline images receive a fresh Content-ID on every draft save (see
  # HasRichText#has_rich_text_parse), so applying a re-saved draft clones another copy
  # into the compose form's UploadCache and leaves the previous one behind. Drop those
  # leftovers, mirroring HasRichText#has_rich_text_cleanup_unused_attachments.
  #
  # Only inline items carrying a Content-ID are considered: images uploaded directly in
  # the editor have none and are referenced by attachment URL instead of by cid.
  def remove_stale_inline_attachments
    active_cids = HasRichText
      .extract_inline_cids(selected_draft.body)
      .flat_map { |cid| [cid, "<#{cid}>"] }

    UploadCache
      .new(meta[:form_id])
      .attachments
      .select { |elem| elem.inline? && inline_attachment_content_id(elem).present? }
      .reject { |elem| active_cids.include?(inline_attachment_content_id(elem)) }
      .each   { |elem| Store.remove_item(elem.id) }
  end

  def inline_attachment_content_id(attachment)
    attachment.preferences['Content-ID'] || attachment.preferences['content_id']
  end

  def selected_draft
    @selected_draft ||= begin
      id         = meta.dig(:additional_data, 'sharedDraftId')
      draft_type = meta.dig(:additional_data, 'draftType') == 'start' ? ::Ticket::SharedDraftStart : ::Ticket::SharedDraftZoom

      Gql::ZammadSchema.authorized_object_from_id(id, type: draft_type, user: context[:current_user]) if id.present?
    end
  end

  def check_applied_field_from_group_key(parent_field, field)
    store_state_group_keys = self.class.instance_variable_get(:@store_state_group_keys)

    return if store_state_group_keys.blank? || store_state_group_keys.exclude?(parent_field.to_s)

    applied_field_from_group_key[field] = parent_field.to_s

  end

  def agent?
    current_user.permissions?('ticket.agent')
  end
end
