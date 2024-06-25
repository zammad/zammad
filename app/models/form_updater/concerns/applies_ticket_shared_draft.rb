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
    selected_draft.content.each_pair do |field, value|
      apply_value.perform(field: field, config: { 'value' => value })
    end
  end

  def selected_draft
    id = meta.dig(:additional_data, 'sharedDraftStartId')
    Gql::ZammadSchema.authorized_object_from_id(id, type: Ticket::SharedDraftStart, user: context[:current_user]) if id.present?
  end

  def agent?
    current_user.permissions?('ticket.agent')
  end
end
