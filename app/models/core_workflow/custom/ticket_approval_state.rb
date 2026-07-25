# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Controls who may change the ticket "approval_state" field.
#
# Agents can always change it. A customer may only change it when they are the
# ticket's assigned approver; for everybody else the field is read-only. This
# keeps the approval decision in the hands of the requested approver (or an
# agent) without exposing it to other organization members who can see the
# shared ticket.
class CoreWorkflow::Custom::TicketApprovalState < CoreWorkflow::Custom::Backend
  APPROVAL_STATE_FIELD = 'approval_state'.freeze
  APPROVER_FIELD       = 'approver'.freeze

  def saved_attribute_match?
    object?(Ticket)
  end

  def selected_attribute_match?
    object?(Ticket)
  end

  def perform
    return if !approval_state_attribute?

    # Agents keep full control over the approval state.
    return if current_user.permissions?('ticket.agent')

    return if current_user_is_approver?

    result('set_readonly', APPROVAL_STATE_FIELD)
  end

  private

  def approval_state_attribute?
    ObjectManager::Attribute.exists?(
      object_lookup_id: ObjectLookup.by_name('Ticket'),
      name:             APPROVAL_STATE_FIELD,
      active:           true,
    )
  end

  def current_user_is_approver?
    approver_id.present? && approver_id.to_s == current_user.id.to_s
  end

  # The currently effective approver: a value being set in the form takes
  # precedence over the value saved on the ticket.
  def approver_id
    if params.present? && params.key?(APPROVER_FIELD)
      params[APPROVER_FIELD]
    else
      saved&.public_send(APPROVER_FIELD)
    end
  end
end
