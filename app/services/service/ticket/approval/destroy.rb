# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Approval::Destroy < Service::BaseWithCurrentUser
  def execute(approval:)
    Pundit.authorize current_user, approval.ticket, :update?
    ensure_requester_or_admin!(approval)

    serialized = serialize_approval(approval)
    
    # Send email notifications before destroying
    Transaction.execute(
      disable: ['Transaction::Notification'],
      user_id: current_user.id,
      interface_handle: 'application_server',
      object: 'TicketApproval',
      type: 'delete',
      object_id: approval.id,
      changes: {
        'status' => [approval.status, 'deleted']
      },
      created_at: Time.zone.now
    ) do
      Transaction::ApprovalNotification.new(
        {
          object: 'TicketApproval',
          type: 'delete',
          object_id: approval.id,
          interface_handle: 'application_server',
          changes: {
            'status' => [approval.status, 'deleted']
          },
          created_at: Time.zone.now,
          user_id: current_user.id,
        },
        { user_id: current_user.id }
      ).perform
    end
    
    approval.destroy!

    serialized
  end

  private

  def ensure_requester_or_admin!(approval)
    return if approval.requester_id == current_user.id || current_user.permissions?('admin')

    raise Exceptions::Forbidden, __('You can only delete your own approval requests.')
  end

  def serialize_approval(approval)
    {
      id:           approval.id,
      ticket_id:    approval.ticket_id,
      approver_id:  approval.approver_id,
      approver:     approval.approver&.fullname,
      requester_id: approval.requester_id,
      requester:    approval.requester&.fullname,
      status:       approval.status,
      priority:     approval.priority,
      message:      approval.message,
      created_at:   approval.created_at,
      updated_at:   approval.updated_at
    }
  end
end
