# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Approval::Update < Service::BaseWithCurrentUser
  VALID_PRIORITIES = Service::Ticket::Approval::Create::VALID_PRIORITIES

  def execute(approval:, attributes: {})
    Pundit.authorize current_user, approval.ticket, :update?
    ensure_requester_or_admin!(approval)

    updates = {}
    updates[:message] = attributes[:message] if attributes.key?(:message)

    if attributes.key?(:priority)
      updates[:priority] = normalize_priority(attributes[:priority])
    end

    approval.update!(updates) if updates.any?
    approval.reload

    # Send email notifications if updates were made
    if updates.any?
      Transaction.execute(
        disable: ['Transaction::Notification'],
        user_id: current_user.id,
        interface_handle: 'application_server',
        object: 'TicketApproval',
        type: 'update',
        object_id: approval.id,
        changes: updates.transform_values { |v| [nil, v] },
        created_at: Time.zone.now
      ) do
        Transaction::ApprovalNotification.new(
          {
            object: 'TicketApproval',
            type: 'update',
            object_id: approval.id,
            interface_handle: 'application_server',
            changes: updates.transform_values { |v| [nil, v] },
            created_at: Time.zone.now,
            user_id: current_user.id,
          },
          { user_id: current_user.id }
        ).perform
      end
    end

    approval
  end

  private

  def ensure_requester_or_admin!(approval)
    return if approval.requester_id == current_user.id || current_user.permissions?('admin')

    raise Exceptions::Forbidden, __('You can only edit your own approval requests.')
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
