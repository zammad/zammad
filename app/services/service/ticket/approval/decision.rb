# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Approval::Decision < Service::BaseWithCurrentUser
  VALID_DECISIONS = {
    approve: 'approved',
    reject:  'rejected'
  }.freeze

  def execute(approval:, decision:)
    Pundit.authorize current_user, approval.ticket, :show?
    ensure_approver!(approval)

    decision_key = decision.to_sym
    new_status = VALID_DECISIONS.fetch(decision_key) do
      raise Exceptions::UnprocessableEntity, __('Unsupported approval decision.')
    end

    if approval.status == new_status
      return approval
    end

    approval.update!(status: new_status)
    approval.reload

    # Send email notifications via Transaction system
    Transaction.execute(
      disable: ['Transaction::Notification'],
      user_id: current_user.id,
      interface_handle: 'application_server',
      object: 'TicketApproval',
      type: decision_key.to_s,
      object_id: approval.id,
      changes: {
        'status' => ['pending', new_status]
      },
      created_at: Time.zone.now
    ) do
      Transaction::ApprovalNotification.new(
        {
          object: 'TicketApproval',
          type: decision_key.to_s,
          object_id: approval.id,
          interface_handle: 'application_server',
          changes: {
            'status' => ['pending', new_status]
          },
          created_at: Time.zone.now,
          user_id: current_user.id,
        },
        { user_id: current_user.id }
      ).perform
    end

    approval
  end

  private

  def ensure_approver!(approval)
    return if approval.approver_id == current_user.id

    raise Exceptions::Forbidden, __('You can only respond to approval requests assigned to you.')
  end
end
