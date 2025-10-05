# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Approval::Create < Service::BaseWithCurrentUser
  VALID_PRIORITIES = %w[low normal high urgent].freeze

  def execute(ticket:, approver_id:, message: nil, priority: nil)
    Pundit.authorize current_user, ticket, :update?

    approver = User.find(approver_id)
    normalized_priority = normalize_priority(priority)

    if ticket.approvals.pending.exists?(approver_id: approver.id)
      raise Exceptions::UnprocessableEntity,
            __('An approval request has already been sent to %s. Please update the existing request.') % approver.fullname
    end

    approval = ticket.approvals.create!(
      approver:  approver,
      requester: current_user,
      message:   message,
      priority:  normalized_priority,
      status:    'pending'
    )

    # Create automatic share if approver is in a different group
    create_auto_share_if_needed(ticket, approver)

    # Send email notifications via Transaction system
    Transaction.execute(
      disable: ['Transaction::Notification'],
      user_id: current_user.id,
      interface_handle: 'application_server',
      object: 'TicketApproval',
      type: 'create',
      object_id: approval.id,
      changes: {
        'status' => [nil, 'pending'],
        'approver_id' => [nil, approver.id],
        'requester_id' => [nil, current_user.id]
      },
      created_at: Time.zone.now
    ) do
      Transaction::ApprovalNotification.new(
        {
          object: 'TicketApproval',
          type: 'create',
          object_id: approval.id,
          interface_handle: 'application_server',
          changes: {
            'status' => [nil, 'pending'],
            'approver_id' => [nil, approver.id],
            'requester_id' => [nil, current_user.id]
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

  def create_auto_share_if_needed(ticket, approver)
    # Get approver's group IDs
    approver_group_ids = approver.group_ids_access('read')
    return if approver_group_ids.empty?

    # Check if approver is in the same group as the ticket
    return if approver_group_ids.include?(ticket.group_id)

    # Find the first group the approver belongs to (excluding the ticket's group)
    approver_group_id = approver_group_ids.find { |id| id != ticket.group_id }
    return unless approver_group_id

    # Check if a share already exists for this group
    return if ticket.shares.active_current.exists?(group_id: approver_group_id)

    # Get the group object
    approver_group = Group.find(approver_group_id)
    return unless approver_group

    # Create automatic share with approver's group
    ticket.shares.create!(
      group:        approver_group,
      shared_by:    current_user,
      permissions:  ['full'],
      message:      __('Automatic share created for approval request'),
      expires_at:   nil, # No expiration for approval-related shares
      status:       'active'
    )
  end

  def normalize_priority(value)
    priority = value.to_s.presence || 'normal'
    unless VALID_PRIORITIES.include?(priority)
      raise Exceptions::UnprocessableEntity,
            __('Approval priority must be one of: %s.') % VALID_PRIORITIES.join(', ')
    end
    priority
  end
end
